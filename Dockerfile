# Use Ruby 3.3.0 slim image
FROM ruby:3.3.0-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
    build-essential \
    git && \
    rm -rf /var/lib/apt/lists/*

# Copy Gemfile first for better caching
COPY Gemfile Gemfile.lock ./

# Install Ruby dependencies
RUN bundle config set --local deployment 'true' && \
    bundle config set --local without 'development test' && \
    bundle install --jobs 4 --retry 3

# Copy application code
COPY . .

# Make executable
RUN chmod +x bin/robot_challenge

# Create non-root user
RUN useradd -m -s /bin/bash robot && \
    chown -R robot:robot /app
USER robot

# Set entrypoint
ENTRYPOINT ["./bin/robot_challenge_interactive.rb"]
CMD []
