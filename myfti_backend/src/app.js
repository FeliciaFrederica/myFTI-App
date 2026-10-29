const express = require("express");

const app = express();

app.use(express.json());

app.get("/api", (req, res) => {
  res.json({
    message: "Welcome to myFTI API!",
  });
});

module.exports = app;