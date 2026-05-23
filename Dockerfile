# Start with a lightweight Linux image that has Node.js v20 pre-installed
FROM node:20-slim

# Install GnuCOBOL directly into the container OS
RUN apt-get update && apt-get install -y gnucobol

# Set the working directory inside the container
WORKDIR /app

# Copy package files and install Node dependencies
COPY package*.json ./
RUN npm install

# Copy the rest of the application files (COBOL source, DAT file, server.js)
COPY . .

# Compile the COBOL binary *inside* the container architecture
RUN cobc -x ACCTINQ.CBL
RUN cobc -x ACCTUPD.CBL

# Expose the API port
EXPOSE 5000

# Start the Node Express server
CMD ["node", "server.js"]