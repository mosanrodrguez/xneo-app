package com.xneo.app

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import androidx.recyclerview.widget.GridLayoutManager
import androidx.recyclerview.widget.RecyclerView
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout

class HomeFragment : Fragment() {
    
    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View? {
        val view = inflater.inflate(R.layout.fragment_home, container, false)
        
        val recyclerView = view.findViewById<RecyclerView>(R.id.video_grid)
        recyclerView.layoutManager = GridLayoutManager(context, 2)
        // recyclerView.adapter = VideoAdapter(videos) // TODO: Implementar
        
        val swipeRefresh = view.findViewById<SwipeRefreshLayout>(R.id.swipe_refresh)
        swipeRefresh.setColorSchemeResources(R.color.red)
        swipeRefresh.setOnRefreshListener {
            // TODO: Cargar videos
            swipeRefresh.isRefreshing = false
        }
        
        return view
    }
}
