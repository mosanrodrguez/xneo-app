package com.xneo.app.ui.home

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import com.bumptech.glide.Glide
import com.xneo.app.R
import com.xneo.app.model.Video

class VideoAdapter(
    private val videos: List<Video>,
    private val onClick: (Video) -> Unit
) : RecyclerView.Adapter<VideoAdapter.ViewHolder>() {

    class ViewHolder(view: View) : RecyclerView.ViewHolder(view) {
        val thumbnail: ImageView = view.findViewById(R.id.iv_thumbnail)
        val tvTitle: TextView = view.findViewById(R.id.tv_title)
        val tvUploader: TextView = view.findViewById(R.id.tv_uploader)
        val tvViews: TextView = view.findViewById(R.id.tv_views)
        val tvTime: TextView = view.findViewById(R.id.tv_time)
        val tvDuration: TextView = view.findViewById(R.id.tv_duration)
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val view = LayoutInflater.from(parent.context).inflate(R.layout.item_video, parent, false)
        return ViewHolder(view)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        val video = videos[position]
        holder.tvTitle.text = video.title
        holder.tvUploader.text = video.uploaderName
        holder.tvViews.text = "${formatNumber(video.views)} vistas"
        holder.tvTime.text = formatTimeAgo(video.uploadDate)
        holder.tvDuration.text = formatDuration(video.duration)
        Glide.with(holder.itemView.context).load(video.thumbnail).into(holder.thumbnail)
        holder.itemView.setOnClickListener { onClick(video) }
    }

    override fun getItemCount() = videos.size

    private fun formatNumber(num: Int): String = when {
        num >= 1000000 -> "${num / 1000000.0}M"
        num >= 1000 -> "${num / 1000.0}K"
        else -> num.toString()
    }

    private fun formatDuration(seconds: Int): String {
        val min = seconds / 60
        val sec = seconds % 60
        return "$min:${sec.toString().padStart(2, '0')}"
    }

    private fun formatTimeAgo(dateStr: String): String {
        if (dateStr.isEmpty()) return ""
        return try {
            val format = java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", java.util.Locale.getDefault())
            val date = format.parse(dateStr) ?: return ""
            val diff = (System.currentTimeMillis() - date.time) / 1000
            when {
                diff < 60 -> "Ahora"
                diff < 3600 -> "${diff / 60}m"
                diff < 86400 -> "${diff / 3600}h"
                else -> "${diff / 86400}d"
            }
        } catch (e: Exception) { "" }
    }
}
