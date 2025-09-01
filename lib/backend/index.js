const express = require("express");
const { createServer } = require("http");
const { Server } = require("socket.io");

const app = express();
const httpServer = createServer(app);

const io = new Server(httpServer, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"],
  },
  transports: ["websocket"],
});

app.get("/", (req, res) => {
  res.send("<h1>🚀 Server is running</h1>");
});

io.on("connection", (socket) => {
  console.log("⚡ User connected:", socket.id);

  // receive message from client
  socket.on("sendMsg", (msg) => {
    console.log("💬 Received:", msg);

    // broadcast back to all clients
    socket.broadcast.emit("sendMsgServer", msg); 
  });

  socket.on("disconnect", () => {
    console.log("❌ User disconnected:", socket.id);
  });
});

io.engine.on("connection_error", (err) => {
  console.log("❌ Connection error:", err.code, err.message);
});


httpServer.listen(3000, "0.0.0.0", () => {
  console.log("✅ Server is running on http://0.0.0.0:3000");
});
