package com.xneo.app.ui.player

import android.os.Bundle
import android.widget.ImageView
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.bumptech.glide.Glide
import com.google.android.exoplayer2.ExoPlayer
import com.google.android.exoplayer2.MediaItem
import com.google.android.exoplayer2.ui.PlayerView
import com.xneo.app.R
import com.xneo.app.network.RetrofitClient
import com.xneo.app.network.SessionManager
import kotlinx.coroutines.*

class VideoPlayerActivity : AppCompatActivity() {
    
    private var player: ExoPlayer? = null
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_player)
        
        val videoUrl = intent.getStringExtra("video_url") ?: ""
        val title = intent.getStringExtra("video_title") ?: ""
        val views = intent.getIntExtra("video_views", 0)
        val likes = intent.getIntExtra("video_likes", 0)
        val dislikes = intent.getIntExtra("video_dislikes", 0)
        val uploader = intent.getStringExtra("video_uploader") ?: ""
        val date = intent.getStringExtra("video_date") ?: ""
        val description = intent.getStringExtra("video_description") ?: ""
        val videoId = intent.getStringExtra("video_id") ?: ""
        
        findViewById<TextView>(R.id.tv_player_title).text = title
        findViewById<TextView>(R.id.tv_player_views).text = "$views vistas"
        findViewById<TextView>(R.id.tv_player_uploader).text = uploader
        findViewById<TextView>(R.id.tv_likes).text = likes.toString()
        findViewById<TextView>(R.id.tv_dislikes).text = dislikes.toString()
        
        if (description.isNotEmpty()) {
            findViewById<TextView>(R.id.tv_player_desc).visibility = android.view.View.VISIBLE
            findViewById<TextView>(R.id.tv_player_desc).text = description
        }
        
        val sessionManager = SessionManager(this)
        CoroutineScope(Dispatchers.IO).launch {
            RetrofitClient.api.viewVideo(videoId)
        }
        
        val playerView = findViewById<PlayerView>(R.id.player_view)
        player = ExoPlayer.Builder(this).build()
        playerView.player = player
        player?.setMediaItem(MediaItem.fromUri(videoUrl))
        player?.prepare()
        player?.playWhenReady = true
        
        findViewById<ImageView>(R.id.btn_back).setOnClickListener { finish() }
        findViewById<android.view.View>(R.id.btn_like).setOnClickListener {
            CoroutineScope(Dispatchers.IO).launch {
                RetrofitClient.api.likeVideo(sessionManager.token ?: "", videoId)
            }
            Toast.makeText(this, "Like", Toast.LENGTH_SHORT).show()
        }
        findViewById<android.view.View>(R.id.btn_share).setOnClickListener {
            val intent = android.content.Intent(android.content.Intent.ACTION_SEND)
            intent.type = "text/plain"
            intent.putExtra(android.content.Intent.EXTRA_TEXT, "Mira este video en XNEO: $videoUrl")
            startActivity(android.content.Intent.createChooser(intent, "Compartir"))
        }
    }
    
    override fun onStop() {
        super.onStop()
        player?.pause()
    }
    
    override fun onDestroy() {
        super.onDestroy()
        player?.release()
        player = null
    }
}
