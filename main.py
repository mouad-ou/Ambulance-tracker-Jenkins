import os
import shutil
from pathlib import Path
from typing import Dict, List, Optional

import numpy as np
import torch
import uvicorn
import whisper
from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from transformers import pipeline

app = FastAPI(title="Ambulance AI Service")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize models
try:
    print("Loading models...")
    speech_model = whisper.load_model("base")
    
    # Load medical pipeline - using Flan-T5 for better medical responses
    medical_qa = pipeline(
        "text2text-generation",
        model="google/flan-t5-large",  # Using large model for better quality
        device="cuda" if torch.cuda.is_available() else "cpu",
        max_length=512
    )
    
    print("Models loaded successfully!")
except Exception as e:
    print(f"Error loading models: {e}")
    raise

class MessageHistory(BaseModel):
    text: str
    isUser: bool
    timestamp: Optional[str] = None

class Query(BaseModel):
    text: str
    conversation_history: List[MessageHistory] = []

class HealthCheck(BaseModel):
    status: str
    models_loaded: bool

def format_medical_response(response: str) -> str:
    """Format the medical response with proper structure."""
    sections = {
        "Assessment": [],
        "Immediate Steps": [],
        "Warning Signs": [],
        "Emergency Care": []
    }
    
    current_section = None
    for line in response.split('\n'):
        line = line.strip()
        if not line:
            continue
            
        if "assess" in line.lower():
            current_section = "Assessment"
        elif "step" in line.lower() or "do" in line.lower():
            current_section = "Immediate Steps"
        elif "warning" in line.lower() or "watch" in line.lower():
            current_section = "Warning Signs"
        elif "emergency" in line.lower() or "hospital" in line.lower():
            current_section = "Emergency Care"
        elif current_section:
            sections[current_section].append(line)
    
    formatted = "First Aid Instructions:\n\n"
    for section, lines in sections.items():
        if lines:
            formatted += f"{section}:\n"
            formatted += "\n".join(f"• {line}" for line in lines)
            formatted += "\n\n"
    
    formatted += """IMPORTANT NOTE:
• This is AI-generated first aid advice only
• For serious injuries, call emergency services immediately
• When in doubt, seek professional medical care"""
    
    return formatted

def get_medical_response(query: str, injury_type: str = None) -> str:
    """Generate detailed medical advice response."""
    if injury_type:
        prompt = f"""As a medical professional, provide detailed first aid instructions for a {injury_type}. Include:
        - How to assess the injury
        - Step-by-step immediate actions to take
        - Warning signs to watch for
        - When emergency care is needed
        Be clear and thorough."""
    else:
        prompt = f"""As a medical professional, assess this situation and provide first aid instructions:
        {query}
        
        Include:
        - How to assess the situation
        - Step-by-step immediate actions
        - Warning signs to watch for
        - When to seek emergency care
        Be clear and thorough."""

    response = medical_qa(prompt, max_length=512)[0]['generated_text']
    return format_medical_response(response)

def get_conversation_response(text: str, history: List[MessageHistory]) -> str:
    """Generate conversational response."""
    # Create context from history
    context = "\n".join([
        f"{'User' if msg.isUser else 'Assistant'}: {msg.text}"
        for msg in history[-3:]
    ])
    
    prompt = f"""Previous conversation:
    {context}
    
    User's message: {text}
    
    Respond as a medical assistant. Be helpful and empathetic. If there are medical concerns,
    provide appropriate guidance."""
    
    response = medical_qa(prompt, max_length=256)[0]['generated_text']
    
    # Add medical advice prompt if no medical keywords found
    if not is_medical_query(text):
        response += "\n\nFeel free to ask any medical questions or first aid advice you need."
    
    return response

@app.get("/health")
async def health_check():
    return HealthCheck(
        status="healthy",
        models_loaded=all([speech_model, medical_qa])
    )

@app.post("/speech-to-text")
async def speech_to_text(audio_file: UploadFile = File(...)):
    try:
        temp_dir = Path("temp")
        temp_dir.mkdir(exist_ok=True)
        
        temp_path = temp_dir / "temp_audio.wav"
        with temp_path.open("wb") as buffer:
            shutil.copyfileobj(audio_file.file, buffer)
        
        result = speech_model.transcribe(str(temp_path))
        
        temp_path.unlink()
        
        return {"text": result["text"]}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        await audio_file.close()

def is_medical_query(text: str) -> bool:
    """Check if the query is medical-related."""
    medical_keywords = [
        'medical', 'health', 'pain', 'hurt', 'injury', 'bleeding', 'sick',
        'disease', 'symptom', 'treatment', 'medicine', 'doctor', 'hospital',
        'emergency', 'first aid', 'wound', 'broken', 'fracture', 'fever',
        'advice', 'help', 'injured', 'cut', 'burn', 'bandage', 'swell',
        'sprain', 'ache', 'nausea', 'dizzy', 'swollen', 'bruise'
    ]
    return any(keyword in text.lower() for keyword in medical_keywords)

@app.post("/virtual-assistant")
async def virtual_assistant(query: Query):
    try:
        current_text = query.text.strip()
        
        if not current_text:
            return {"response": "Hello! I'm your medical assistant. How can I help you today?"}

        # Extract injury type if present
        injury_types = {
            'fracture': ['fracture', 'broken bone', 'broken'],
            'cut': ['cut', 'bleeding', 'wound'],
            'burn': ['burn', 'burned', 'burning'],
            'sprain': ['sprain', 'twisted', 'twist'],
            'head injury': ['head injury', 'concussion', 'hit head'],
            'choking': ['choking', 'can\'t breathe', 'difficulty breathing']
        }
        
        found_injury = None
        for injury, keywords in injury_types.items():
            if any(keyword in current_text.lower() for keyword in keywords):
                found_injury = injury
                break

        if is_medical_query(current_text):
            response = get_medical_response(current_text, found_injury)
        else:
            response = get_conversation_response(current_text, query.conversation_history)

        return {"response": response}
    except Exception as e:
        print(f"Error in virtual assistant: {e}")
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    port = int(os.getenv("PORT", 8000)) 
    uvicorn.run("main:app", host="0.0.0.0", port=port, reload=True)