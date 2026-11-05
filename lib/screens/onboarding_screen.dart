import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/onboarding_provider.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<OnboardingProvider>();
    final colores = Theme.of(context).colorScheme;
    final paginas = OnboardingProvider.paginas;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => prov.terminar(context),
                child: const Text('Saltar'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: prov.controlador,
                itemCount: paginas.length,
                onPageChanged: prov.alCambiarPagina,
                itemBuilder: (context, i) {
                  final p = paginas[i];
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 72,
                              backgroundColor: colores.primaryContainer,
                              child: Icon(p.icono, size: 72, color: colores.onPrimaryContainer),
                            ),
                            const SizedBox(height: 40),
                            Text(
                              p.titulo,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              p.texto,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  // Indicadores de página
                  for (var i = 0; i < paginas.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.only(right: 8),
                      width: i == prov.pagina ? 28 : 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: i == prov.pagina ? colores.primary : colores.outlineVariant,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => prov.siguiente(context),
                    child: Text(prov.esUltima ? 'Comenzar' : 'Siguiente'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
