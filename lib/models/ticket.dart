class Ticket {
  int? id;
  String title;
  String description;
  String? status;
  String? createdAt;
  String? clientName;

  Ticket({
    this.id,
    required this.title,
    required this.description,
    this.status,
    this.createdAt,
    this.clientName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'createdAt': createdAt,
      'clientName': clientName,
    };
  }

  factory Ticket.fromMap(Map<String, dynamic> map) {
    return Ticket(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      status: map['status'],
      createdAt: map['createdAt'],
      clientName: map['clientName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'createdAt': createdAt,
      'clientName': clientName,
    };
  }

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      status: json['status'],
      createdAt: json['createdAt'],
      clientName: json['clientName'],
    );
  }
}
