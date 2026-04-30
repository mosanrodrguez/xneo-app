package com.xneo.app.model

data class AuthResponse(
    val token: String,
    val user: User
)

data class LoginRequest(
    val username: String,
    val password: String
)

data class RegisterRequest(
    val username: String,
    val password: String
)
