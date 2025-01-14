from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import whisper
from transformers import pipeline
import uvicorn
from pydantic import BaseModel
from typing import List, Dict, Optional
import numpy as np
import os
import shutil
from pathlib import Path
import torch

app = FastAPI(title="Ambulance AI Service")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize models with smaller versions
try:
    print("Loading models...")
    speech_model = whisper.load_model("tiny")  # Changed from 'base' to 'tiny'
    
    # Load medical pipeline - using smaller T5 model
    medical_qa = pipeline(
        "text2text-generation",
        model="google/flan-t5-small",  # Changed from 'large' to 'small'
        device="cpu",  # Force CPU usage to save memory
        max_length=512
    )
    
    print("Models loaded successfully!")
except Exception as e:
    print(f"Error loading models: {e}")
    raise

# Rest of your code remains the same...
[Rest of your existing code]