package com.xneo.app.model

import com.google.gson.annotations.SerializedName

data class Video(
    @SerializedName("id") val id: String = "",
    @SerializedName("title") val title: String = "",
    @SerializedName("videoUrl") val videoUrl: String? = null,
    @SerializedName("thumbnail") val thumbnail: String? = null,
    @SerializedName("views") val views: Int = 0,
    @SerializedName("likes") val likes: Int = 0,
    @SerializedName("dislikes") val dislikes: Int = 0,
    @SerializedName("duration") val duration: Int = 0,
    @SerializedName("category") val category: String? = null,
    @SerializedName("uploaderName") val uploaderName: String = "Usuario",
    @SerializedName("uploaderAvatar") val uploaderAvatar: String? = null,
    @SerializedName("userId") val userId: String = "",
    @SerializedName("uploadDate") val uploadDate: String = "",
    @SerializedName("description") val description: String? = null
)
