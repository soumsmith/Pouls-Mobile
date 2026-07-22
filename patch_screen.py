import re

file_path = 'lib/screens/establishment_screen.dart'
with open(file_path, 'r') as f:
    content = f.read()

# 1. Update ImageMenuCardExternalTitle call around line 1092
card_update = """                  tag: items[i].typePrincipal,
                  tag2: items[i].ordreEnseignement,
                  tag2Color: const Color(0xFF00796B),"""
content = re.sub(r'tag:\s*items\[i\]\.typePrincipal,', card_update, content)

# 2. Update the search filtering in _loadEcoles or _onSearchChanged if they do local filtering
# Let's check how _loadEcoles handles search
# If it's done via API, we might not need to change local filtering unless they filter locally
