import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:orsocook/services/auth_service.dart';
import 'package:orsocook/models/comment.dart';

@immutable
class CommentItemWidget extends StatelessWidget {
  final Comment comment;
  final bool isEditing;
  final bool isSubmitting;
  final String? editCommentId;
  final TextEditingController editCommentController;
  final Function(String) onUpdateComment;
  final Function(String) onDeleteComment;
  final Function() onCancelEdit;
  final Function(Comment) onStartEdit;

  const CommentItemWidget({
    super.key,
    required this.comment,
    required this.isEditing,
    required this.isSubmitting,
    required this.editCommentId,
    required this.editCommentController,
    required this.onUpdateComment,
    required this.onDeleteComment,
    required this.onCancelEdit,
    required this.onStartEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final currentUserId = authService.userId;
        final isOwnComment =
            currentUserId != null && comment.isOwner(currentUserId);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(26),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            borderRadius: BorderRadius.circular(12),
            elevation: 0,
            color: Colors.white,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {},
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCommentHeader(
                        context, isOwnComment, authService, theme),
                    const SizedBox(height: 12),
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 250),
                      crossFadeState: isEditing && editCommentId == comment.id
                          ? CrossFadeState.showFirst
                          : CrossFadeState.showSecond,
                      firstChild: _buildEditForm(context, theme),
                      secondChild: _buildCommentContent(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCommentHeader(BuildContext context, bool isOwnComment,
      AuthService authService, ThemeData theme) {
    // Crea una GlobalKey per il pulsante delle azioni
    final actionButtonKey = GlobalKey();

    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: theme.colorScheme.secondaryContainer,
          backgroundImage: comment.userAvatar != null
              ? NetworkImage(comment.userAvatar!)
              : null,
          child: comment.userAvatar == null
              ? Text(
                  comment.userName[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                comment.userName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                comment.timeAgo,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        if (isOwnComment && !isEditing && editCommentId != comment.id)
          _buildCommentActions(context, theme, actionButtonKey),
      ],
    );
  }

  Widget _buildCommentActions(
      BuildContext context, ThemeData theme, GlobalKey actionButtonKey) {
    final colorScheme = theme.colorScheme;
    final baseColor = colorScheme.secondaryContainer;
    final outlineColor = colorScheme.outline;

    return Container(
      key: actionButtonKey, // Assegna la GlobalKey al contenitore
      child: GestureDetector(
        onTap: () {
          _showCustomPopupMenu(context, colorScheme, actionButtonKey);
        },
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: outlineColor.withAlpha((0.2 * 255).round()),
              width: 1,
            ),
            color: baseColor.withAlpha((0.95 * 255).round()),
          ),
          child: Icon(
            Icons.more_vert_rounded,
            size: 20,
            color: colorScheme.onSecondaryContainer,
          ),
        ),
      ),
    );
  }

  void _showCustomPopupMenu(
      BuildContext context, ColorScheme colorScheme, GlobalKey buttonKey) {
    // Ottieni il render box usando la GlobalKey
    final renderBox =
        buttonKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox == null) return;

    // Ottieni la posizione del pulsante
    final offset = renderBox.localToGlobal(Offset.zero);

    // Calcola la dimensione dello schermo per il posizionamento
    final screenSize = MediaQuery.of(context).size;

    // Calcola la posizione del menu
    final left = offset.dx;
    final top = offset.dy + renderBox.size.height;
    final right = screenSize.width - (offset.dx + renderBox.size.width);
    final bottom = screenSize.height - (offset.dy + renderBox.size.height);

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(left, top, right, bottom),
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: colorScheme.outline.withAlpha((0.1 * 255).round()),
        ),
      ),
      items: [
        PopupMenuItem<String>(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          value: 'edit',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.edit_outlined,
                size: 18,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Text(
                'Modifica',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 6),
        PopupMenuItem<String>(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          value: 'delete',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.delete_outline,
                size: 18,
                color: Colors.red,
              ),
              const SizedBox(width: 10),
              const Text(
                'Elimina',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'edit') {
        onStartEdit(comment);
      } else if (value == 'delete') {
        onDeleteComment(comment.id);
      }
    });
  }

  Widget _buildEditForm(BuildContext context, ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        TextField(
          controller: editCommentController,
          maxLines: 3,
          minLines: 1,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            labelText: 'Modifica commento',
            labelStyle: TextStyle(color: colorScheme.primary),
            floatingLabelBehavior: FloatingLabelBehavior.always,
          ),
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: onCancelEdit,
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.close, size: 16),
                  SizedBox(width: 6),
                  Text('ANNULLA'),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed:
                  isSubmitting ? null : () => onUpdateComment(comment.id),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isSubmitting
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.onPrimary,
                      ),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, size: 16),
                        SizedBox(width: 6),
                        Text('SALVA'),
                      ],
                    ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCommentContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText(
          comment.content,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: Colors.black87,
          ),
        ),
        if (comment.isEdited)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '(modificato)',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
}
