import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class BlogContent extends StatefulWidget {
  final String content;
  final String slug; // Nhận slug để tracking

  const BlogContent({
    Key? key, 
    required this.content,
    required this.slug,
  }) : super(key: key);

  @override
  State<BlogContent> createState() => _BlogContentState();
}

class _BlogContentState extends State<BlogContent> {
  bool _hasTracked = false;

  @override
  void initState() {
    super.initState();
    _trackPostView();
  }

  void _trackPostView() async {
    if (_hasTracked) return;
    
    try {
      // Gọi API get blog by slug - sẽ tự động tăng views trong database
      final response = await http.get(
        Uri.parse('https://your-api-domain.com/api/blog/detail/${widget.slug}'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        print('✅ Đã ghi nhận lượt xem bài viết ${widget.slug}');
        _hasTracked = true;
      } else {
        print('❌ Lỗi tracking: ${response.statusCode}');
      }
    } catch (e) {
      // Fail silently - không ảnh hưởng đến trải nghiệm người dùng
      print('⚠️ Tracking failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final decodedContent = decodeHtmlEntities(widget.content);
    final plainText = _stripHtmlTags(decodedContent);
    
    // Kiểm tra xem có chứa bảng không
    if (_containsTable(decodedContent)) {
      return _buildContentWithTables(decodedContent);
    }
    
    return _buildPlainTextContent(plainText);
  }

  Widget _buildPlainTextContent(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        color: Colors.black87,
        height: 1.6,
      ),
      textAlign: TextAlign.justify,
    );
  }

  Widget _buildContentWithTables(String htmlContent) {
    final lines = htmlContent.split('\n');
    final List<Widget> widgets = [];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      if (line.startsWith('<table') || _isTableRow(line)) {
        // Xử lý bảng
        final tableData = _extractTableData(lines, i);
        if (tableData.data.isNotEmpty) {
          widgets.add(_buildTableWidget(tableData.data));
          i = tableData.lastIndex; // Nhảy đến cuối bảng
        }
      } else {
        // Văn bản thông thường
        final cleanText = _stripHtmlTags(line);
        if (cleanText.isNotEmpty) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                cleanText,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  height: 1.6,
                ),
                textAlign: TextAlign.justify,
              ),
            ),
          );
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildTableWidget(List<List<String>> tableData) {
    // Kiểm tra nếu bảng rỗng
    if (tableData.isEmpty) return const SizedBox();

    // Tính toán số cột dựa trên hàng đầu tiên (header)
    final columnCount = tableData.first.length;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 12,
          horizontalMargin: 12,
          headingRowColor: MaterialStateProperty.all(Colors.blue[50]),
          dataRowColor: MaterialStateProperty.all(Colors.white),
          border: TableBorder(
            horizontalInside: BorderSide(color: Colors.grey[300]!),
            verticalInside: BorderSide(color: Colors.grey[300]!),
            top: BorderSide(color: Colors.grey[300]!),
            bottom: BorderSide(color: Colors.grey[300]!),
            left: BorderSide(color: Colors.grey[300]!),
            right: BorderSide(color: Colors.grey[300]!),
          ),
          columns: List.generate(columnCount, (index) {
            return DataColumn(
              label: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _stripHtmlTags(tableData[0][index]),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }),
          rows: List.generate(tableData.length - 1, (rowIndex) {
            final rowData = tableData[rowIndex + 1];
            return DataRow(
              cells: List.generate(columnCount, (cellIndex) {
                final cellContent = cellIndex < rowData.length 
                    ? _stripHtmlTags(rowData[cellIndex])
                    : '';
                return DataCell(
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      cellContent,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                );
              }),
            );
          }),
        ),
      ),
    );
  }

  bool _containsTable(String htmlContent) {
    return htmlContent.contains('<table') || 
           htmlContent.contains('<tr') || 
           htmlContent.contains('<td');
  }

  bool _isTableRow(String line) {
    return line.startsWith('<tr') || line.contains('<td');
  }

  TableData _extractTableData(List<String> lines, int startIndex) {
    final List<List<String>> tableData = [];
    int currentIndex = startIndex;
    List<String> currentRow = [];
    
    while (currentIndex < lines.length) {
      final line = lines[currentIndex].trim();
      
      if (line.startsWith('</table>')) {
        // Kết thúc bảng
        if (currentRow.isNotEmpty) {
          tableData.add(List.from(currentRow));
          currentRow.clear();
        }
        break;
      }
      
      if (line.startsWith('<tr') || line.contains('<td')) {
        // Xử lý hàng và ô
        final rowData = _extractRowData(line);
        if (rowData.isNotEmpty) {
          currentRow.addAll(rowData);
        }
        
        // Nếu kết thúc hàng
        if (line.contains('</tr>') || (currentIndex + 1 < lines.length && lines[currentIndex + 1].contains('</tr>'))) {
          if (currentRow.isNotEmpty) {
            tableData.add(List.from(currentRow));
            currentRow.clear();
          }
        }
      }
      
      currentIndex++;
    }
    
    return TableData(tableData, currentIndex);
  }

  List<String> _extractRowData(String line) {
    final List<String> rowData = [];
    
    // Regex để tìm tất cả các ô td trong hàng
    final regex = RegExp(r'<td[^>]*>(.*?)</td>', caseSensitive: false, dotAll: true);
    final matches = regex.allMatches(line);
    
    for (final match in matches) {
      if (match.groupCount >= 1) {
        String cellContent = match.group(1)!.trim();
        // Loại bỏ các thẻ HTML còn sót lại trong ô
        cellContent = _stripHtmlTags(cellContent);
        rowData.add(cellContent);
      }
    }
    
    return rowData;
  }

  String _stripHtmlTags(String htmlString) {
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    String result = htmlString.replaceAll(exp, '').trim();
    
    // Replace multiple spaces with single space
    result = result.replaceAll(RegExp(r'\s+'), ' ');
    
    // Decode HTML entities trong nội dung đã được làm sạch
    result = decodeHtmlEntities(result);
    
    return result;
  }

  String decodeHtmlEntities(String htmlString) {
    final Map<String, String> htmlEntities = {
      // Vietnamese characters - lowercase
      '&agrave;': 'à', '&aacute;': 'á', '&acirc;': 'â', '&atilde;': 'ã', 
      '&egrave;': 'è', '&eacute;': 'é', '&ecirc;': 'ê', 
      '&igrave;': 'ì', '&iacute;': 'í', '&icirc;': 'î', 
      '&ograve;': 'ò', '&oacute;': 'ó', '&ocirc;': 'ô', '&otilde;': 'õ', 
      '&ugrave;': 'ù', '&uacute;': 'ú', '&ucirc;': 'û',
      '&yacute;': 'ý', '&yuml;': 'ÿ',
      
      // Vietnamese characters - uppercase  
      '&Agrave;': 'À', '&Aacute;': 'Á', '&Acirc;': 'Â', '&Atilde;': 'Ã',
      '&Egrave;': 'È', '&Eacute;': 'É', '&Ecirc;': 'Ê',
      '&Igrave;': 'Ì', '&Iacute;': 'Í', '&Icirc;': 'Î',
      '&Ograve;': 'Ò', '&Oacute;': 'Ó', '&Ocirc;': 'Ô', '&Otilde;': 'Õ',
      '&Ugrave;': 'Ù', '&Uacute;': 'Ú', '&Ucirc;': 'Û',
      '&Yacute;': 'Ý', '&Yuml;': 'Ÿ',
      
      // Quotes
      '&ldquo;': '"', '&rdquo;': '"', '&quot;': '"',
      '&lsquo;': "'", '&rsquo;': "'", '&apos;': "'",
      
      // Special characters
      '&nbsp;': ' ', '&amp;': '&', '&lt;': '<', '&gt;': '>',
      '&ndash;': '–', '&mdash;': '—', '&hellip;': '…',
    };

    String result = htmlString;
    htmlEntities.forEach((entity, character) {
      result = result.replaceAll(entity, character);
    });
    
    return result;
  }
}

class TableData {
  final List<List<String>> data;
  final int lastIndex;

  TableData(this.data, this.lastIndex);
}