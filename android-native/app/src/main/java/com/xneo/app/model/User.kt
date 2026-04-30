package com.xneo.app.model

data class User(
    val id: String = "",
    val username: String = "",
    val avatar: String? = null,
    val info: String? = null,
    val category: String? = "Hetero",
    val role: String? = null
)
