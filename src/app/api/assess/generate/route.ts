import { NextResponse } from 'next/server';
import { db } from '@/lib/firebase-admin';
import { GoogleGenAI } from '@google/genai';

// Initialize Gemini Client
const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY || '' });

export async function POST(req: Request) {
  try {
    const { sessionId } = await req.json();

    if (!sessionId) {
      return NextResponse.json({ error: 'Session ID required' }, { status: 400 });
    }

    // Fetch session from Firestore
    const sessionRef = db.collection('sessions').doc(sessionId);
    const sessionDoc = await sessionRef.get();

    if (!sessionDoc.exists) {
      return NextResponse.json({ error: 'Session not found' }, { status: 404 });
    }

    const session = sessionDoc.data();

    if (!session || !session.codeSnippet) {
      return NextResponse.json({ error: 'Code snippet not found in session' }, { status: 404 });
    }

    // Call Gemini to generate a bug in the code
    const prompt = `You are a ruthless technical assessor. 
Review the following code snippet. 
Introduce exactly ONE subtle logical bug (e.g., boundary condition, state mutation). 
Do NOT introduce syntax errors, the code must still compile/run but produce incorrect results.
Output the buggy code and a 1-sentence description of the symptom in strict JSON format like this:
{"buggyCode": "...", "symptom": "..."}

Code Snippet:
${session.codeSnippet}
`;

    const response = await ai.models.generateContent({
      model: 'gemini-1.5-pro',
      contents: prompt,
      config: {
        responseMimeType: 'application/json',
      },
    });

    const resultText = response.text;
    
    if (!resultText) {
      throw new Error('Gemini returned empty response');
    }

    const result = JSON.parse(resultText);

    return NextResponse.json({ 
      success: true, 
      buggyCode: result.buggyCode, 
      symptom: result.symptom 
    }, { status: 200 });

  } catch (error) {
    console.error('Assess Generate Error:', error);
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}
