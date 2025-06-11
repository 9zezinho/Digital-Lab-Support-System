/// This class represents the predefined Modules to assign to Lecturers
class Module{
  final String name;

  Module({required this.name});

  //Static list of predefined modules
  static List<Module> get predefinedModules => [
    Module(name: "Mathematics-101"),
    Module(name: "Physics-211"),
    Module(name: "Biology-301"),
    Module(name: "Computer Science-101"),
    Module(name: "Mechanical Eng-101"),
    Module(name: "Accountant-305"),
    Module(name: "Pharmacy-268"),
    Module(name: "Business-249"),
    Module(name: "Chemistry-215"),
    Module(name: "Aerospace-356"),
  ];
}