from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import pickle
import numpy as np
import pandas as pd

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

with open('Placement_model.pkl', 'rb') as f:
    model = pickle.load(f)

class InputData(BaseModel):
    iq: float
    cgpa: float

@app.post("/predict/")
async def prediction(data: InputData):
    try:
        # Create DataFrame with EXACTLY the same column names used during training
        X = pd.DataFrame([[data.iq, data.cgpa]], columns=['IQ', 'CGPA'])
        
        # Debug print to verify input values
        print(f"Received input - IQ: {data.iq}, CGPA: {data.cgpa}")
        print(f"DataFrame:\n{X}")
        
        pred = model.predict(X)[0]
        
        # Debug print prediction result
        print(f"Raw prediction: {pred}, Type: {type(pred)}")
        
        return {"Placed": int(pred)}
    except Exception as e:
        # Print full error traceback
        import traceback
        traceback.print_exc()
        return {"error": str(e)}