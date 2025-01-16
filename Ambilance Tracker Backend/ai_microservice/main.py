import os
import shutil
from pathlib import Path
from typing import List, Optional

import torch
import uvicorn
from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from transformers import AutoModelForCausalLM, AutoTokenizer
import whisper

# Initialize FastAPI
app = FastAPI(title="Ambulance AI Service")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Check for GPU availability
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
print(f"Using device: {device}")

# Initialize models
try:
    print("Loading models...")
    # Load Whisper model
    speech_model = whisper.load_model("base").to(device)
    
    model_name = "EleutherAI/gpt-neo-1.3B"
    tokenizer = AutoTokenizer.from_pretrained(model_name, padding_side="left")
    if tokenizer.pad_token is None:
        tokenizer.pad_token = tokenizer.eos_token
    gpt_neo_model = AutoModelForCausalLM.from_pretrained(model_name).to(device)
    
    print("Models loaded successfully!")
except Exception as e:
    print(f"Error loading models: {e}")
    raise

# Pydantic models
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
    device: str

# Helper functions
def get_gpt_neo_response(user_input: str) -> str:
    """Generate response using GPT-Neo."""
    system_prompt = (
        "You are a professional health assistant. Always recommend consulting a healthcare professional for serious issues. "
        "Do not attempt to diagnose conditions but provide general advice.\n\n"
        "User: {user_input}\nAssistant: "
    )
    input_text = system_prompt.format(user_input=user_input)
    inputs = tokenizer(input_text, return_tensors="pt", padding=True, truncation=True)
    
    # Move inputs to GPU
    inputs = {k: v.to(device) for k, v in inputs.items()}
    
    with torch.cuda.amp.autocast():  # Enable automatic mixed precision
        output = gpt_neo_model.generate(
            inputs['input_ids'],
            attention_mask=inputs['attention_mask'],
            max_length=200,
            num_return_sequences=1,
            temperature=0.7,
            top_p=0.9,
            no_repeat_ngram_size=2
        )
    
    response = tokenizer.decode(output[0], skip_special_tokens=True)
    return response.split("Assistant:")[-1].strip()

def get_conversation_response(text: str, history: List[MessageHistory]) -> str:
    """Generate conversational response."""
    context = "\n".join([
        f"{'User' if msg.isUser else 'Assistant'}: {msg.text}"
        for msg in history[-3:]
    ])
    
    prompt = f"""Previous conversation:
    {context}
    
    User's message: {text}
    
    Respond as a medical assistant. Be helpful and empathetic. Provide appropriate guidance."""
    
    response = get_gpt_neo_response(prompt)
    return response

@app.get("/health")
async def health_check():
    return HealthCheck(
        status="healthy",
        models_loaded=all([speech_model, gpt_neo_model]),
        device=str(device)
    )

@app.post("/speech-to-text")
async def speech_to_text(audio_file: UploadFile = File(...)):
    try:
        temp_dir = Path("temp")
        temp_dir.mkdir(exist_ok=True)
        
        temp_path = temp_dir / "temp_audio.wav"
        with temp_path.open("wb") as buffer:
            shutil.copyfileobj(audio_file.file, buffer)
        
        # Use GPU for inference
        with torch.cuda.amp.autocast():
            result = speech_model.transcribe(str(temp_path))
        
        temp_path.unlink()
        return {"text": result["text"]}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        await audio_file.close()

@app.post("/virtual-assistant")
async def virtual_assistant(query: Query):
    try:
        current_text = query.text.strip()
        
        if not current_text:
            return {"response": "Hello! I'm your medical assistant. How can I help you today?"}
        
        # Use conversation history if available
        if query.conversation_history:
            response = get_conversation_response(current_text, query.conversation_history)
        else:
            response = get_gpt_neo_response(current_text)
            
        return {"response": response}
    except Exception as e:
        print(f"Error in virtual assistant: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# Main entry point
if __name__ == "__main__":
    port = int(os.getenv("PORT", 8000))
    uvicorn.run("main:app", host="0.0.0.0", port=port, reload=True)