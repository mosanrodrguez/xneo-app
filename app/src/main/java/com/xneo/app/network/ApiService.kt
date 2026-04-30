package com.xneo.app.network

import com.xneo.app.model.AuthResponse
import com.xneo.app.model.LoginRequest
import com.xneo.app.model.RegisterRequest
import com.xneo.app.model.User
import com.xneo.app.model.Video
import okhttp3.MultipartBody
import okhttp3.RequestBody
import retrofit2.Response
import retrofit2.http.*

interface ApiService {
    
    @POST("api/auth/login")
    suspend fun login(@Body request: LoginRequest): Response<AuthResponse>
    
    @POST("api/auth/register")
    suspend fun register(@Body request: RegisterRequest): Response<AuthResponse>
    
    @GET("api/auth/me")
    suspend fun getProfile(@Header("Authorization") token: String): Response<User>
    
    @GET("api/videos")
    suspend fun getVideos(@Header("Authorization") token: String): Response<List<Video>>
    
    @GET("api/videos/mine")
    suspend fun getMyVideos(@Header("Authorization") token: String): Response<List<Video>>
    
    @Multipart
    @POST("api/upload/video")
    suspend fun uploadVideo(
        @Header("Authorization") token: String,
        @Part video: MultipartBody.Part,
        @Part("title") title: RequestBody,
        @Part("description") description: RequestBody,
        @Part("category") category: RequestBody
    ): Response<Void>
    
    @POST("api/videos/{id}/like")
    suspend fun likeVideo(
        @Header("Authorization") token: String,
        @Path("id") videoId: String
    ): Response<Void>
    
    @POST("api/videos/{id}/dislike")
    suspend fun dislikeVideo(
        @Header("Authorization") token: String,
        @Path("id") videoId: String
    ): Response<Void>
    
    @POST("api/videos/{id}/view")
    suspend fun viewVideo(@Path("id") videoId: String): Response<Void>
}
