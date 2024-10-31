import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

// Ponto de entrada do aplicativo
void main() {
  runApp(HairstyleChangerApp());
}

// Widget principal do aplicativo
class HairstyleChangerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hairstyle Changer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HairstyleChangerScreen(),
    );
  }
}

// Tela principal onde os usuários podem selecionar e enviar uma imagem
class HairstyleChangerScreen extends StatefulWidget {
  @override
  _HairstyleChangerScreenState createState() => _HairstyleChangerScreenState();
}

class _HairstyleChangerScreenState extends State<HairstyleChangerScreen> {
  // Armazena a imagem selecionada pelo usuário
  File? _selectedImage;
  final picker = ImagePicker();

  // Task ID da API para consultar o status de processamento da imagem
  String? _taskId = '1730337904220.84d4099e-7b6e-46aa-91ee-b4bb460bb602';
  
  // URL da imagem processada retornada pela API
  String? _imageUrl;

  // Função para selecionar uma imagem da galeria do dispositivo
  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // Função para enviar a imagem para a API e iniciar o processamento
  Future<void> _sendImage() async {
    if (_selectedImage == null) return; // Verifica se a imagem foi selecionada

    // Configura o endpoint da API e os cabeçalhos
    final url = Uri.parse('https://hairstyle-changer-pro.p.rapidapi.com/facebody/editing/hairstyle-pro');
    final headers = {
      // Define o token de autenticação da API
      'X-Rapidapi-Key': '4e6acc0803msh94a00a7c36ce9c5p1239e4jsn74aa1218a688',
      // Define o host da API
      'X-Rapidapi-Host': 'hairstyle-changer-pro.p.rapidapi.com',
    };

    // Constrói a requisição de envio de imagem com multipart
    var request = http.MultipartRequest('POST', url)
      ..headers.addAll(headers)
      ..fields['task_type'] = 'async'
      ..fields['hair_style'] = 'CurlyShag' // Define o estilo de cabelo
      ..files.add(await http.MultipartFile.fromPath(
        'image',
        _selectedImage!.path,
        filename: 'maenormal.jpg',
      ));

    // Envia a requisição e aguarda a resposta
    final response = await request.send();

    // Trata a resposta da API
    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final decodedData = json.decode(responseData);
      setState(() {
        _taskId = decodedData['task_id']; // Salva o Task ID para consultas futuras
      });
      print('Task ID: $_taskId');
    } else {
      print('Erro: ${response.statusCode}');
    }
  }

  // Função para recuperar a imagem processada usando o Task ID
  Future<void> _retrieveImage() async {
    if (_taskId == null) return; // Verifica se o Task ID foi definido

    // Define o endpoint para consulta do status do processamento
    final url = Uri.parse('https://hairstyle-changer-pro.p.rapidapi.com/api/rapidapi/query-async-task-result?task_id=$_taskId');
    final headers = {
      'X-Rapidapi-Key': '4e6acc0803msh94a00a7c36ce9c5p1239e4jsn74aa1218a688',
      'X-Rapidapi-Host': 'hairstyle-changer-pro.p.rapidapi.com',
    };

    // Envia uma requisição GET para consultar o status e resultado do processamento
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final decodedData = json.decode(response.body);
      print('Response Data: $decodedData'); // Exibe os dados completos da resposta

      // Verifica se a tarefa foi concluída com sucesso
      if (decodedData['error_code'] == 0 && decodedData['task_status'] == 2) {
        // Extrai a URL da imagem processada
        if (decodedData['data'] != null && decodedData['data']['images'] != null) {
          setState(() {
            _imageUrl = decodedData['data']['images'][0]; // Primeira URL na lista 'images'
          });
          print('Imagem URL: $_imageUrl');
        } else {
          print('URL da imagem não encontrada na resposta.');
        }
      } else {
        print('A tarefa ainda está sendo processada ou ocorreu um erro.');
      }
    } else {
      print('Erro ao recuperar imagem: ${response.statusCode}');
    }
  }

  // Constrói a interface do usuário
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hairstyle Changer'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Exibe a imagem selecionada pelo usuário ou um texto padrão
            _selectedImage != null
                ? Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                : Text('Nenhuma imagem selecionada'),
            SizedBox(height: 20),

            // Botão para selecionar uma imagem
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Selecionar Imagem'),
            ),
            SizedBox(height: 20),

            // Botão para enviar a imagem selecionada para a API
            ElevatedButton(
              onPressed: _sendImage,
              child: Text('Enviar Imagem para Hairstyle'),
            ),
            SizedBox(height: 20),

            // Botão para recuperar a imagem processada da API
            ElevatedButton(
              onPressed: _retrieveImage,
              child: Text('Recuperar Imagem com Task ID Pré-definido'),
            ),
            SizedBox(height: 20),

            // Exibe a imagem processada em um Card pequeno, ou uma mensagem padrão
            _imageUrl != null
                ? Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Container(
                        width: 150, // Tamanho reduzido do card
                        height: 150,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _imageUrl!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  )
                : Text('Nenhuma imagem recuperada'),
          ],
        ),
      ),
    );
  }
}
