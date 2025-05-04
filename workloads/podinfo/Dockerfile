# Stage 1: Build the Go application
FROM golang:1.24.2-alpine AS builder

# Set the working directory inside the container
WORKDIR /app

# Copy go.mod and go.sum files
COPY ./src/go.mod ./src/go.sum ./

# Download Go module dependencies, this way we use docker layer caching if only the code changes docker can reuse the layer
RUN go mod download -x

# Copy the entire project source code
COPY ./src .

# Build the Go application
# Adjust the GOOS and GOARCH if you need to target a different platform
# RUN GOOS=linux GOARCH=amd64 go build -o podinfo .
# Stripping debug information from binary.
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags='-w -s' -o podinfo .

# Stage 2: Create a minimal runtime image
FROM alpine:latest

# Install necessary runtime dependencies (if any)
# For most Go REST APIs, you might not need extra dependencies in a static build.
# If your application relies on specific libraries (e.g., for database drivers
# that require C bindings), you might need to install them here.
# Example for PostgreSQL:
# RUN apk add --no-cache libpq

# Create a non-root user with ID 100 and name 'app'
RUN adduser -D -u 1000 app

# Set the working directory
WORKDIR /app

# Copy the built binary from the builder stage
COPY --from=builder /app/podinfo .

# Change ownership of the application files to the 'app' user
RUN chown -R app:app /app

# Switch to the non-root user
USER app

# Expose the port your application listens on (default is often 8080)
EXPOSE 8080

# Command to run the application
CMD ["./podinfo"]