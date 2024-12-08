from fastapi import FastAPI, WebSocket, HTTPException
import subprocess
import os
import uuid
import shutil

app = FastAPI()
sessions = {}

@app.post("/start-session")
async def start_session(exeUrl: str):
    session_id = str(uuid.uuid4())
    session_dir = f"/tmp/{session_id}"
    os.makedirs(session_dir, exist_ok=True)

    # Download the .exe file
    exe_path = os.path.join(session_dir, "app.exe")
    result = subprocess.run(["wget", "-O", exe_path, exeUrl], capture_output=True)
    if result.returncode != 0:
        raise HTTPException(status_code=400, detail="Failed to download the .exe file")

    # Start Docker container for the session
    docker_cmd = [
        "docker", "run", "--rm", "--name", session_id,
        "-v", f"{session_dir}:/sandbox",
        "wine-image", "xvfb-run", "wine", "/sandbox/app.exe"
    ]
    process = subprocess.Popen(docker_cmd)

    # Save session metadata
    sessions[session_id] = {"process": process, "dir": session_dir}
    return {"session_id": session_id}

@app.websocket("/input/{session_id}")
async def handle_input(websocket: WebSocket, session_id: str):
    await websocket.accept()
    if session_id not in sessions:
        await websocket.close(code=404)
        return
    try:
        while True:
            data = await websocket.receive_text()
            # Process user input and forward to the container (e.g., using xdotool)
    except Exception:
        pass
    finally:
        terminate_session(session_id)

def terminate_session(session_id):
    if session_id in sessions:
        process = sessions[session_id]["process"]
        process.terminate()
        shutil.rmtree(sessions[session_id]["dir"], ignore_errors=True)
        del sessions[session_id]
