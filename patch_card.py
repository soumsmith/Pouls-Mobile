import re

file_path = 'lib/widgets/image_menu_card_external_title.dart'
with open(file_path, 'r') as f:
    content = f.read()

# Add to properties
content = re.sub(
    r'(final String\? tag;)',
    r'\1\n  final String? tag2;\n  final Color? tag2Color;',
    content
)

# Add to constructor
content = re.sub(
    r'(this\.tag,)',
    r'\1\n    this.tag2,\n    this.tag2Color,',
    content
)

# Replace the Positioned with a Row for tags
tag_replacement = """          Positioned(
            top: 8,
            right: 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (tag != null)
                  Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tag!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (tag2 != null)
                  Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: tag2Color ?? Colors.grey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tag2!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),"""

# Let's find the original positioned block
# We will just replace it using regex
pattern = r"Positioned\(\s*top: 8,\s*right: 8,\s*child: Container\(.+?child: tag != null.+?SizedBox\.shrink\(\), // Espace vide mais même taille\s*\),\s*\),"
content = re.sub(pattern, tag_replacement, content, flags=re.DOTALL)

with open(file_path, 'w') as f:
    f.write(content)

print("Card updated")
