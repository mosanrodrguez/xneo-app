import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';
import '../models/user.dart';
import 'conversation_screen.dart';

const API_URL = 'https://xneo-web.onrender.com';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<User> _users = [];
  List<User> _filteredUsers = [];
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    
    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      final response = await http.get(
        Uri.parse('$API_URL/api/users'),
        headers: {'Authorization': 'Bearer ${auth.token}'},
      );
      
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        setState(() {
          _users = data.map((u) => User.fromJson(u)).toList();
          _filteredUsers = _users;
        });
      }
    } catch (e) {
      // Datos de ejemplo para desarrollo
      setState(() {
        _users = [
          User(id: '1', username: 'Usuario1', avatar: null, category: 'Hetero'),
          User(id: '2', username: 'Usuario2', avatar: null, category: 'Bi'),
          User(id: '3', username: 'Usuario3', avatar: null, category: 'Gay'),
          User(id: '4', username: 'Usuario4', avatar: null, category: 'Trans'),
          User(id: '5', username: 'Usuario5', avatar: null, category: 'Hetero'),
        ];
        _filteredUsers = _users;
      });
    }
    
    setState(() => _isLoading = false);
  }

  void _filterUsers(String query) {
    setState(() {
      _filteredUsers = _users
          .where((user) => user.username.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Usuarios', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              showSearch(
                context: context,
                delegate: UserSearchDelegate(users: _users),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchUsers,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFE53935)))
            : _filteredUsers.isEmpty
                ? const Center(child: Text('No hay usuarios registrados', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFE53935),
                          child: user.avatar != null
                              ? ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: user.avatar!,
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Text(user.username[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        title: Text(user.username, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(user.category ?? 'Sin categoría', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ConversationScreen(
                                chatId: 'chat_${user.id}',
                                otherUserId: user.id,
                                otherUsername: user.username,
                                otherAvatar: user.avatar,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
      ),
    );
  }
}

class UserSearchDelegate extends SearchDelegate<String> {
  final List<User> users;

  UserSearchDelegate({required this.users});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = users.where((u) => u.username.toLowerCase().contains(query.toLowerCase())).toList();
    return _buildUserList(results, context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final results = query.isEmpty ? users : users.where((u) => u.username.toLowerCase().contains(query.toLowerCase())).toList();
    return _buildUserList(results, context);
  }

  Widget _buildUserList(List<User> users, BuildContext context) {
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFFE53935),
            child: Text(user.username[0].toUpperCase()),
          ),
          title: Text(user.username),
          subtitle: Text(user.category ?? ''),
          onTap: () {
            close(context, user.username);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ConversationScreen(
                  chatId: 'chat_${user.id}',
                  otherUserId: user.id,
                  otherUsername: user.username,
                  otherAvatar: user.avatar,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
