#!/bin/sh
# Netcat-based shutdown listener.
# Listens on $PORT (default 5000) for HTTP requests. If the request
# line matches POST /shutdown or GET /shutdown the service will reply
# with a 200 and call `sudo poweroff`.

PORT=${PORT:-5000}

echo "Shutdown listener started on port $PORT..."

while true; do
  FIFO="/tmp/shutdown_fifo_$$"
  REQFILE="/tmp/shutdown_request_$$.txt"
  rm -f "$FIFO" "$REQFILE"
  mkfifo "$FIFO"

  # Start nc to listen; its stdin will come from FIFO (the response)
  # and its stdout will be captured to REQFILE (the request).
  # Use -q 1 so nc exits shortly after stdin closes (prevents curl hanging)
  nc -l -p "$PORT" -q 1 < "$FIFO" > "$REQFILE" 2>/dev/null &
  NC_PID=$!

  # Small pause to ensure nc is listening
  sleep 0.1

  # Send a simple HTTP response when a client connects. This will block
  # until nc reads from the FIFO (i.e., until a client connects).
  printf 'HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\nShutting down...\n' > "$FIFO" || true

  # Remove FIFO now that response has been written
  rm -f "$FIFO"

  # Wait for nc to finish and capture the request
  wait "$NC_PID" 2>/dev/null || true

  REQLINE=$(head -n 1 "$REQFILE" 2>/dev/null || true)
  rm -f "$REQFILE"

  case "$REQLINE" in
    "POST /shutdown "*|"POST /shutdown"|"GET /shutdown "*|"GET /shutdown")
      echo "Valid shutdown request received: $REQLINE"
      # Trigger safe system shutdown
      sudo poweroff
      exit 0
      ;;
    *)
      echo "Ignored request: $REQLINE"
      ;;
  esac
done