from flask import Flask, request
import datetime
import os

app = Flask(__name__)


@app.route("/health")
def health():
    return "ok"


@app.route("/notes")
def notes():
    # Get custom content from query parameter
    content = request.args.get("content", "")
    if not content:
        content = "No content provided"

    # Write to notes file
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    note_entry = f"[{timestamp}] {content}\n"

    # Get file path from environment variable
    notes_file_path = os.getenv("NOTES_FILE_PATH", "./notes.txt")

    # Ensure the directory exists
    os.makedirs(os.path.dirname(notes_file_path), exist_ok=True)

    with open(notes_file_path, "a") as f:
        f.write(note_entry)

    return f"Note logged: {content}"


if __name__ == "__main__":
    PORT = int(os.getenv("PORT", "8000"))
    print(f"Server running on http://localhost:{PORT}")
    print(f"Visit http://localhost:{PORT}/notes?content=your_message to log a note")
    app.run(host="0.0.0.0", port=PORT, debug=True)
