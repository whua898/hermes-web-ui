import sqlite3

db = sqlite3.connect(r'C:\Users\wh898\AppData\Local\hermes\state.db')

sessions = db.execute('''
    SELECT s.id, s.title, s.started_at, COUNT(m.id) as msg_count 
    FROM sessions s LEFT JOIN messages m ON m.session_id = s.id 
    GROUP BY s.id ORDER BY s.started_at DESC LIMIT 6
''').fetchall()

for sid, title, created, count in sessions:
    print(f'=== {sid} | {title or "(untitled)"} | msgs:{count} ===')
    # Get user messages only for quick overview
    msgs = db.execute('''
        SELECT role, substr(content,1,500) 
        FROM messages WHERE session_id=? AND role='user'
        ORDER BY id LIMIT 5
    ''', (sid,)).fetchall()
    for role, content in msgs:
        content_clean = content.replace('\n', ' ').replace('\r', '')[:300]
        print(f'  [{role}] {content_clean}')
    print()

# Now get detailed content for the "patching" related sessions
print('\n\n===== DETAILED PATCH SESSION MESSAGES =====')
patch_sessions = db.execute('''
    SELECT s.id, s.title FROM sessions s 
    WHERE s.title LIKE '%patch%' OR s.title LIKE '%补丁%' OR s.title LIKE '%Python%'
    ORDER BY s.started_at DESC LIMIT 5
''').fetchall()

for sid, title in patch_sessions:
    print(f'\n=== {sid} | {title} ===')
    msgs = db.execute('''
        SELECT role, content FROM messages 
        WHERE session_id=? ORDER BY id
    ''', (sid,)).fetchall()
    for role, content in msgs:
        # Truncate long content
        if len(content) > 500:
            content = content[:500] + f'... [truncated, total {len(content)} chars]'
        content_clean = content.replace('\n', '\n  ')[:600]
        print(f'  [{role}] {content_clean}')

db.close()
