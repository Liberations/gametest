enum CellType { box1, boxOpen, door, gift, monster }

class GridCell {
  CellType type;
  bool isOpened;
  String? contentId; // optional id for gift variants or other content

  GridCell({required this.type, this.isOpened = false, this.contentId});
}
