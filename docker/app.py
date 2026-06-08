import sys
import json
from http.server import HTTPServer, BaseHTTPRequestHandler

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        try:
            response = json.dumps({
                "status": "running",
                "message": "Security lab web app",
                "phase": "Phase 8 - Docker"
            }).encode()
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Content-Length', len(response))
            self.end_headers()
            self.wfile.write(response)
            self.wfile.flush()
        except Exception as e:
            print(f"Handler error: {e}", flush=True, file=sys.stderr)

    def log_message(self, format, *args):
        print(f"Request: {args}", flush=True, file=sys.stderr)

if __name__ == "__main__":
    print("APP STARTING", flush=True, file=sys.stderr)
    try:
        server = HTTPServer(("0.0.0.0", 8080), Handler)
        print("Server running on port 8080", flush=True, file=sys.stderr)
        server.serve_forever()
    except Exception as e:
        print(f"ERROR: {e}", flush=True, file=sys.stderr)
        sys.exit(1)
