#!/bin/bash

# Check if correct arguments are provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <config-directory-path>"
    exit 1
fi

CONFIG_DIR="$1"
PORT=22000  # Starting port
IMAGE="quay.io/qubip/pq-container:latest"  # Container image

# Check if the provided config directory exists
if [ ! -d "$CONFIG_DIR" ]; then
    echo "Error: Directory '$CONFIG_DIR' does not exist."
    exit 1
fi

# Kill all existing containers
echo "Stopping and removing all existing containers..."
podman ps -a -q | xargs -I {} podman rm -f {}

echo "Starting containers using image: $IMAGE"

for CONFIG in "$CONFIG_DIR"/*.conf; do
    INSTANCE_NAME="nginx_$(basename "$CONFIG" .conf)"
    ((PORT++))

    # Ensure the correct permissions for the config file
    chmod 644 "$CONFIG"

    # Run the container with the updated image and port 443, ensuring Nginx stays in the foreground
    podman run -d --name "$INSTANCE_NAME" \
        -v "$CONFIG":/etc/nginx/nginx.conf:rw,z \
        -p "$PORT":443 $IMAGE nginx -g "daemon off;"

    echo "Started $INSTANCE_NAME on port $PORT with config $CONFIG"

    # Check if Nginx is running inside the container using ps aux | grep nginx
    echo "Checking if Nginx is running inside $INSTANCE_NAME..."

    # Execute 'ps aux' and show the output for the grep nginx command
    podman exec "$INSTANCE_NAME" ps aux | grep -q "nginx"

    if [ $? -eq 0 ]; then
        echo "Nginx is running inside $INSTANCE_NAME."
    else
        echo "Error: Nginx is not running inside $INSTANCE_NAME!"
    fi

    # Display the full output of 'ps aux | grep nginx'
    echo "Displaying output of 'ps aux | grep nginx' for $INSTANCE_NAME:"
    podman exec "$INSTANCE_NAME" ps aux | grep "nginx"
done

# Display running containers
echo "All containers are running. Listing them below:"
podman ps -a

exit 0

