import { NextResponse } from 'next/server';
import { db } from '@/lib/firebase-admin';
import { GoogleGenAI } from '@google/genai';

const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY || '' });

export async function POST(req: Request) {
  try {
    const { sessionId, fixedCode, originalBuggyCode } = await req.json();

    if (!sessionId || !fixedCode) {
      return NextResponse.json({ error: 'Session ID and fixedCode required' }, { status: 400 });
    }

    const sessionRef = db.collection('sessions').doc(sessionId);
    const sessionDoc = await sessionRef.get();

    if (!sessionDoc.exists) {
      return NextResponse.json({ error: 'Session not found' }, { status: 404 });
    }

    const session = sessionDoc.data();

    if (!session || !session.codeSnippet) {
      return NextResponse.json({ error: 'Original code snippet not found in session' }, { status: 404 });
    }

    // Call Gemini to evaluate the user's fix
    const prompt = `You are a ruthless technical assessor evaluating a candidate's bug fix.
I will provide the original code (which was correct), the buggy code we showed the user, and the user's fixed code.
Determine if the user successfully fixed the bug and returned the logic to a correct state.

Original Correct Code:
${session.codeSnippet}

Buggy Code We Showed Them:
${originalBuggyCode}

User's Fixed Code:
${fixedCode}

Output strict JSON like this:
{"passed": true|false, "explanation": "1-sentence explanation of why they passed or failed."}
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

    // If passed, update session status in Firestore
    if (result.passed) {
      await sessionRef.update({
        status: 'VERIFIED'
      });
    }

    return NextResponse.json({ 
      success: true, 
      passed: result.passed, 
      explanation: result.explanation 
    }, { status: 200 });

  } catch (error) {
    console.error('Assess Submit Error:', error);
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}
