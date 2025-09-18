import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Lógica de la animación
  StateMachineController? controller;

  // STATE MACHINE INPUT
  SMIBool? isChecking; // oso mira
  SMIBool? isHandsUp; // se tapa los ojos
  SMITrigger? trigSuccess; // feliz
  SMITrigger? trigFail; // triste
  SMINumber? numLook; // controla dirección ojos

  // Mostrar/ocultar contraseña
  bool _isHiden = true;

  // Focus y timers
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  Timer? _emailTimer;
  Timer? _passwordTimer;

  @override
  void initState() {
    super.initState();

    // Listener focus email
    _emailFocus.addListener(() {
      if (_emailFocus.hasFocus) {
        isChecking?.change(true);
      } else {
        _emailTimer?.cancel();
        isChecking?.change(false);
      }
    });

    // Listener focus password
    _passwordFocus.addListener(() {
      if (_passwordFocus.hasFocus) {
        if (_isHiden) isHandsUp?.change(true);
      } else {
        isHandsUp?.change(false);
      }
    });
  }

  @override
  void dispose() {
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailTimer?.cancel();
    _passwordTimer?.cancel();
    super.dispose();
  }

  void _onEmailChanged(String value) {
    _emailTimer?.cancel();
    isHandsUp?.change(false);
    isChecking?.change(true);

    if (numLook != null) {
      numLook!.value = (value.length * 3).toDouble().clamp(0, 60);
    }

    _emailTimer = Timer(const Duration(seconds: 2), () {
      isChecking?.change(false);
    });
  }

  void _onPasswordChanged(String value) {
    _passwordTimer?.cancel();
    isChecking?.change(false);
    if (_isHiden) {
      isHandsUp?.change(true);
    } else {
      isHandsUp?.change(false);
    }

    _passwordTimer = Timer(const Duration(seconds: 2), () {
      isHandsUp?.change(false);
    });
  }

  void _togglePasswordView() {
    setState(() {
      _isHiden = !_isHiden;
      if (_isHiden && _passwordFocus.hasFocus) {
        isHandsUp?.change(true);
      } else {
        isHandsUp?.change(false);
      }
    });
  }

  // VALIDACIÓN DE EMAIL Y CONTRASEÑA
  void _validateLogin() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Validación email
    bool isEmailValid = RegExp(
      r'^[\w\.\-]+@(gmail\.com|outlook\.com|hotmail\.com)$'
    ).hasMatch(email);

    // Validación contraseña
    bool isPasswordValid = false;
    if (password.length >= 8) {
      final firstLetter = password[0];
      final hasFirstUpper = RegExp(r'[A-Z]').hasMatch(firstLetter);
      final hasLetter = RegExp(r'[A-Za-z]').hasMatch(password);
      final hasNumber = RegExp(r'[0-9]').hasMatch(password);
      final hasSpecial = RegExp(r'[!@#\$&*~,\.\-_]').hasMatch(password);

      if (hasFirstUpper && hasLetter && hasNumber && hasSpecial) {
        isPasswordValid = true;
      }
    }

    // Animación del oso según validaciones
    if (isEmailValid && isPasswordValid) {
      trigSuccess?.fire(); // feliz
    } else {
      trigFail?.fire(); // triste
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        isChecking?.change(false);
        isHandsUp?.change(false);
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: size.width,
                  height: 200,
                  child: RiveAnimation.asset(
                    'animated_login_character.riv',
                    stateMachines: ["login machine"],
                    onInit: (artboard) {
                      controller = StateMachineController.fromArtboard(
                        artboard,
                        "Login Machine",
                      );
                      if (controller == null) return;
                      artboard.addController(controller!);

                      isChecking = controller!.findSMI('isChecking');
                      isHandsUp = controller!.findSMI('isHandsUp');
                      trigSuccess = controller!.findSMI('trigSuccess');
                      trigFail = controller!.findSMI('trigFail');
                      numLook = controller!.findSMI('numLook');
                    },
                  ),
                ),
                const SizedBox(height: 10),
                // Campo Email
                TextField(
                  controller: _emailController,
                  focusNode: _emailFocus,
                  onChanged: _onEmailChanged,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: "Email",
                    prefixIcon: const Icon(Icons.mail),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Campo Password
                TextField(
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  onChanged: _onPasswordChanged,
                  obscureText: _isHiden,
                  decoration: InputDecoration(
                    hintText: "Password",
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isHiden ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: _togglePasswordView,
                      tooltip: _isHiden
                          ? 'Mostrar contraseña'
                          : 'Ocultar contraseña',
                    ),
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: size.width,
                  child: const Text(
                    "Forgot Password?",
                    textAlign: TextAlign.right,
                    style: TextStyle(decoration: TextDecoration.underline),
                  ),
                ),
                const SizedBox(height: 10),
                MaterialButton(
                  minWidth: size.width,
                  height: 50,
                  color: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onPressed: _validateLogin, // <--- botón Login
                  child: const Text(
                    "Login",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        "Register",
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
