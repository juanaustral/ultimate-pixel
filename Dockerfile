FROM rust:1-bookworm
RUN apt-get update && apt-get install -y --no-install-recommends \
    libwebkit2gtk-4.1-dev libgtk-3-dev librsvg2-dev libayatana-appindicator3-dev \
    libssl-dev libxdo-dev build-essential file curl wget xdg-utils nodejs npm \
  && rm -rf /var/lib/apt/lists/*
RUN npm install -g @tauri-apps/cli@2
WORKDIR /app
