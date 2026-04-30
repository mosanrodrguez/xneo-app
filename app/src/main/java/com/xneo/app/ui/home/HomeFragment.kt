package com.xneo.app.ui.home

import android.content.Intent
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import androidx.recyclerview.widget.GridLayoutManager
import androidx.recyclerview.widget.RecyclerView
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout
import com.xneo.app.R
import com.xneo.app.model.Video
import com.xneo.app.network.RetrofitClient
import com.xneo.app.network.SessionManager
import com.xneo.app.ui.player.VideoPlayerActivity
import kotlinx.coroutines.*

class HomeFragment : Fragment() {

    private lateinit var recyclerView: RecyclerView
    private lateinit var swipeRefresh: SwipeRefreshLayout
    private lateinit var sessionManager: SessionManager
    private val videos = mutableListOf<Video>()
    private lateinit var adapter: VideoAdapter

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View {
        val view = inflater.inflate(R.layout.fragment_home, container, false)

        sessionManager = SessionManager(requireContext())
        recyclerView = view.findViewById(R.id.video_grid)
        swipeRefresh = view.findViewById(R.id.swipe_refresh)

        adapter = VideoAdapter(videos) { video ->
            val intent = Intent(requireContext(), VideoPlayerActivity::class.java)
            intent.putExtra("video_id", video.id)
            intent.putExtra("video_title", video.title)
            intent.putExtra("video_url", video.videoUrl)
            intent.putExtra("video_views", video.views)
            intent.putExtra("video_likes", video.likes)
            intent.putExtra("video_dislikes", video.dislikes)
            intent.putExtra("video_uploader", video.uploaderName)
            intent.putExtra("video_date", video.uploadDate)
            intent.putExtra("video_description", video.description)
            startActivity(intent)
        }

        recyclerView.layoutManager = GridLayoutManager(context, 2)
        recyclerView.adapter = adapter

        swipeRefresh.setColorSchemeResources(android.R.color.holo_red_dark)
        swipeRefresh.setOnRefreshListener { loadVideos() }

        loadVideos()
        return view
    }

    private fun loadVideos() {
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val response = RetrofitClient.api.getVideos(sessionManager.token ?: "")
                if (response.isSuccessful) {
                    val newVideos = response.body() ?: emptyList()
                    withContext(Dispatchers.Main) {
                        videos.clear()
                        videos.addAll(newVideos)
                        adapter.notifyDataSetChanged()
                        swipeRefresh.isRefreshing = false
                    }
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) { swipeRefresh.isRefreshing = false }
            }
        }
    }
}
