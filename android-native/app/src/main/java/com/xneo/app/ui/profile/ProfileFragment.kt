package com.xneo.app.ui.profile

import android.content.Intent
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.fragment.app.Fragment
import com.xneo.app.network.SessionManager
import com.xneo.app.ui.login.LoginActivity

class ProfileFragment : Fragment() {
    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View? {
        val view = inflater.inflate(android.R.layout.simple_list_item_1, container, false)
        
        val sessionManager = SessionManager(requireContext())
        view.findViewById<TextView>(android.R.id.text1)?.text = sessionManager.username
        
        view.setOnClickListener {
            sessionManager.logout()
            startActivity(Intent(requireContext(), LoginActivity::class.java))
            requireActivity().finish()
        }
        
        return view
    }
}
