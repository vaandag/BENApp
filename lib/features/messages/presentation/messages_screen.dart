import 'package:flutter/material.dart';
import '../../../models/memory.dart';

class MessagesScreen extends StatefulWidget {
  final Memory? memoryToShare;
  const MessagesScreen({super.key, this.memoryToShare});
  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _Chat {
  final int id;
  final String name;
  final String initials;
  final String preview;
  final String time;
  final int unread;
  final bool online;
  const _Chat(this.id, this.name, this.initials, this.preview, this.time, this.unread, this.online);
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _search = TextEditingController();
  final _chats = const [
    _Chat(2, 'Lina Yılmaz', 'LY', 'Haritadaki şu anıya baktın mı?', '22:14', 2, true),
    _Chat(3, 'Mert Kaya', 'MK', 'Yarın sahilde misin?', '21:42', 0, true),
    _Chat(4, 'Nehir Akın', 'NA', 'O fotoğraf gerçekten çok iyi.', '20:08', 5, false),
    _Chat(5, 'Arda Demir', 'AD', 'Konumu sana attım.', 'Dün', 0, false),
    _Chat(6, 'Ece Su', 'ES', 'BEN\'de yeni bir şey gördüm 👀', 'Pzt', 1, true),
  ];
  String _query = '';

  @override
  void dispose() { _search.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final chats = _chats.where((c) => c.name.toLowerCase().contains(_query.toLowerCase())).toList();
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
          child: Row(children: [
            const Expanded(child: Text('Yeni konuşma', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900))),
            _RoundAction(icon: Icons.edit_rounded, onTap: () => _newMessage(context)),
          ]),
        )),
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
          child: TextField(
            controller: _search,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(prefixIcon: const Icon(Icons.search_rounded), hintText: 'Kişi ara...', suffixIcon: _query.isEmpty ? null : IconButton(onPressed: () { _search.clear(); setState(() => _query = ''); }, icon: const Icon(Icons.close_rounded))),
          ),
        )),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        if (chats.isEmpty)
          const SliverFillRemaining(hasScrollBody: false, child: Center(child: Text('Bu kişi bulunamadı.')))
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 110),
            sliver: SliverList.builder(
              itemCount: chats.length,
              itemBuilder: (_, i) => _ChatTile(chat: chats[i], onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _ChatScreen(chat: chats[i], sharedText: widget.memoryToShare == null ? null : _shareText(widget.memoryToShare!))))),
            ),
          ),
      ],
    );
  }

  String _shareText(Memory memory) => 'BEN anısı: ${memory.title ?? memory.text ?? 'Bir anı'}';

  void _newMessage(BuildContext context) {
    String query = '';
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(builder: (context, setSheetState) {
          final results = _chats.where((c) => c.name.toLowerCase().contains(query.toLowerCase())).toList();
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Align(alignment: Alignment.centerLeft, child: Text('Yeni konuşma', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900))),
                  const SizedBox(height: 12),
                  TextField(
                    autofocus: true,
                    onChanged: (v) => setSheetState(() => query = v),
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded), hintText: 'Kişi ara...'),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 300,
                    child: results.isEmpty
                        ? const Center(child: Text('Kişi bulunamadı.'))
                        : ListView.builder(
                            itemCount: results.length,
                            itemBuilder: (_, i) {
                              final chat = results[i];
                              return ListTile(
                                leading: _Avatar(chat: chat),
                                title: Text(chat.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                                subtitle: const Text('Yeni konuşma başlat'),
                                onTap: () {
                                  Navigator.pop(sheetContext);
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => _ChatScreen(chat: chat, sharedText: widget.memoryToShare == null ? null : _shareText(widget.memoryToShare!))));
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

}

class _RoundAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 46,
          height: 46,
          child: Icon(Icons.edit_rounded, size: 21),
        ),
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final _Chat chat;
  final VoidCallback onTap;
  const _ChatTile({required this.chat, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: [
              _Avatar(chat: chat),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(chat.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(chat.preview, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .58))),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(chat.time, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .45))),
                if (chat.unread > 0)
                  Container(margin: const EdgeInsets.only(top: 7), padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: const BoxDecoration(color: Color(0xFFFFD200), borderRadius: BorderRadius.all(Radius.circular(99))), child: Text('${chat.unread}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900))),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final _Chat chat;
  final double size;
  const _Avatar({required this.chat, this.size = 52});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.zero,
      decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFD200), Color(0xFFFF8A00)])),
      child: Container(
        decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF1A2435), border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 0)),
        alignment: Alignment.center,
        child: Text(chat.initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
      ),
    );
  }
}

class _Message {
  String text;
  final bool mine;
  bool read;
  _Message(this.text,{required this.mine,this.read=false});
}

class _ChatScreen extends StatefulWidget {
  final _Chat chat;
  final String? sharedText;
  const _ChatScreen({required this.chat, this.sharedText});
  @override State<_ChatScreen> createState()=>_ChatScreenState();
}

class _ChatScreenState extends State<_ChatScreen> {
  final _controller=TextEditingController();
  late final List<_Message> _messages;
  @override void initState(){super.initState();_messages=[_Message('Selam! BEN\'de seni gördüm.',mine:false,read:true),_Message('Haritadaki anıyı açtım, baya iyiymiş 😄',mine:true,read:true),_Message('Bugün yeni bir şey bıraktım.',mine:false,read:true)]; if(widget.sharedText != null) _messages.add(_Message(widget.sharedText!, mine:true, read:false));}
  @override void dispose(){_controller.dispose();super.dispose();}
  void _send(){
    final text=_controller.text.trim();
    if(text.isEmpty)return;
    setState(()=>_messages.add(_Message(text,mine:true,read:false)));
    _controller.clear();
    Future.delayed(const Duration(milliseconds: 850), () {
      if (!mounted) return;
      setState(() => _messages.add(_Message(_autoReply(text), mine: false, read: true)));
    });
  }

  String _autoReply(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('harita') || lower.contains('konum')) return 'Haritadan bakıyorum 👀';
    if (lower.contains('merhaba') || lower.contains('selam')) return 'Selam! 👋 BEN’deyim.';
    if (lower.contains('anı')) return 'Anıyı gördüm, çok güzelmiş. 📍';
    return 'Gördüm, birazdan tekrar yazarım. ✨';
  }
  void _edit(int i){final c=TextEditingController(text:_messages[i].text);showDialog(context:context,builder:(ctx)=>AlertDialog(title:const Text('Mesajı düzenle'),content:TextField(controller:c,autofocus:true,maxLines:4),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Vazgeç')),FilledButton(onPressed:(){final t=c.text.trim();if(t.isNotEmpty)setState(()=>_messages[i].text=t);Navigator.pop(ctx);},child:const Text('Kaydet'))]));}
  void _delete(int i){setState(()=>_messages.removeAt(i));}
  void _menu(int i){if(!_messages[i].mine)return;showModalBottomSheet(context:context,showDragHandle:true,builder:(c)=>SafeArea(child:Column(mainAxisSize:MainAxisSize.min,children:[ListTile(leading:const Icon(Icons.edit_outlined),title:const Text('Düzenle'),onTap:(){Navigator.pop(c);_edit(i);}),ListTile(leading:const Icon(Icons.delete_outline,color:Colors.red),title:const Text('Sil'),onTap:(){Navigator.pop(c);_delete(i);})])));}

  @override Widget build(BuildContext context){return Scaffold(appBar:AppBar(title:Row(children:[_Avatar(chat:widget.chat,size:38),const SizedBox(width:10),Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(widget.chat.name,style:const TextStyle(fontSize:16,fontWeight:FontWeight.w900)),Text(widget.chat.online?'şu an aktif':'geçmişte aktif',style:const TextStyle(fontSize:10))])])),body:Column(children:[Expanded(child:ListView.builder(padding:const EdgeInsets.all(18),itemCount:_messages.length,itemBuilder:(_,i){final m=_messages[i];return GestureDetector(onLongPress:()=>_menu(i),child:Align(alignment:m.mine?Alignment.centerRight:Alignment.centerLeft,child:Container(margin:const EdgeInsets.only(bottom:10),padding:const EdgeInsets.symmetric(horizontal:14,vertical:11),decoration:BoxDecoration(color:m.mine?const Color(0xFFFFD200):Theme.of(context).colorScheme.surface,borderRadius:BorderRadius.circular(18)),child:Column(crossAxisAlignment:m.mine?CrossAxisAlignment.end:CrossAxisAlignment.start,children:[Text(m.text,style:TextStyle(fontWeight:FontWeight.w600,color:m.mine?const Color(0xFF101217):null)),if(m.mine)Padding(padding:const EdgeInsets.only(top:4),child:Text(m.read?'Okundu ✓✓':'Gönderildi ✓',style:TextStyle(fontSize:10,color:const Color(0xFF101217).withValues(alpha:.65),fontWeight:FontWeight.w700))) ]))));})),SafeArea(child:Padding(padding:const EdgeInsets.fromLTRB(12,6,12,10),child:Row(children:[Expanded(child:TextField(controller:_controller,textInputAction:TextInputAction.send,onSubmitted:(_)=>_send(),decoration:const InputDecoration(hintText:'Mesaj yaz...'))),const SizedBox(width:8),FloatingActionButton.small(onPressed:_send,child:const Icon(Icons.send_rounded))])))]));}
}
