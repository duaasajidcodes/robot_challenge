# Use Ruby 3.3.0 slim image for smaller size
FROM ruby:3.3.0-slim

# Set working directory
WORKDIR /app

# Install system dependencies including Redis
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
    build-essential \
    git \
    redis-server && \
    rm -rf /var/lib/apt/lists/*

# Copy Gemfile and Gemfile.lock first for better Docker layer caching
COPY Gemfile Gemfile.lock ./

# Install Ruby dependencies
RUN bundle config set --local deployment 'true' && \
    bundle config set --local without 'development test' && \
    bundle install --jobs 4 --retry 3

# Copy application code
COPY . .

# Make the executable script runnable
RUN chmod +x bin/robot_challenge

# Create a non-root user for security
RUN useradd -m -s /bin/bash robot
USER robot

# Set the entrypoint
ENTRYPOINT ["./bin/robot_challenge"]

# Default command (can be overridden)
CMD []
