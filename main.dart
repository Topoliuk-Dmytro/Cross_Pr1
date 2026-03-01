import 'package:flutter/material.dart';

void main() => runApp(const FuelCalcApp());

class FuelCalcApp extends StatelessWidget {
  const FuelCalcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fuel Calc',
      home: const FuelCalcPage(),
    );
  }
}

class FuelCalcPage extends StatefulWidget {
  const FuelCalcPage({super.key});

  @override
  State<FuelCalcPage> createState() => _FuelCalcPageState();
}

class _FuelCalcPageState extends State<FuelCalcPage> {
  // Variant 22 => last digit 2 (table 1.3)
  final _h = TextEditingController(text: '4.2');
  final _c = TextEditingController(text: '62.1');
  final _s = TextEditingController(text: '3.30');
  final _n = TextEditingController(text: '1.20');
  final _o = TextEditingController(text: '6.40');
  final _w = TextEditingController(text: '7.0');
  final _a = TextEditingController(text: '15.8');

  String _out = '';

  double _p(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '.').trim()) ?? double.nan;

  String _fmt(double x, {int d = 3}) => x.isNaN ? '—' : x.toStringAsFixed(d);

  void _calc() {
    final Hr = _p(_h);
    final Cr = _p(_c);
    final Sr = _p(_s);
    final Nr = _p(_n);
    final Or = _p(_o);
    final Wr = _p(_w);
    final Ar = _p(_a);

    final vals = [Hr, Cr, Sr, Nr, Or, Wr, Ar];
    if (vals.any((v) => v.isNaN)) {
      setState(() => _out = 'Помилка: перевір числа (можна і з комою, і з крапкою).');
      return;
    }

    if (Wr >= 100 || Wr < 0 || Ar < 0 || (Wr + Ar) >= 100) {
      setState(() => _out = 'Помилка: умови мають бути 0 ≤ W < 100 і W + A < 100.');
      return;
    }

    // Coefficients (as in example)
    final Krs = 100.0 / (100.0 - Wr);          // K_РС
    final Krg = 100.0 / (100.0 - Wr - Ar);     // K_РГ

    // Dry composition
    final Hc = Hr * Krs;
    final Cc = Cr * Krs;
    final Sc = Sr * Krs;
    final Nc = Nr * Krs;
    final Oc = Or * Krs;
    final Ac = Ar * Krs;

    // Combustible (горюча) composition (no water, no ash)
    final Hg = Hr * Krg;
    final Cg = Cr * Krg;
    final Sg = Sr * Krg;
    final Ng = Nr * Krg;
    final Og = Or * Krg;

    // Lower heating value for working mass (Mendeleev, kJ/kg)
    final Qr_kJ = 339.0 * Cr + 1030.0 * Hr - 108.8 * (Or - Sr) - 25.0 * Wr;
    final Qr_MJ = Qr_kJ / 1000.0;

    // Simple basis conversion (per kg of dry / combustible part)
    final Qd_MJ = Qr_MJ * 100.0 / (100.0 - Wr);
    final Qg_MJ = Qr_MJ * 100.0 / (100.0 - Wr - Ar);

    final sumDry = Hc + Cc + Sc + Nc + Oc + Ac;
    final sumComb = Hg + Cg + Sg + Ng + Og;

    setState(() {
      _out = [
        'Коефіцієнти:',
        'Kₚс = 100/(100−Wᵖ) = ${_fmt(Krs, d: 4)}',
        'Kₚг = 100/(100−Wᵖ−Aᵖ) = ${_fmt(Krg, d: 4)}',
        '',
        'Суха маса (%):',
        'Hᶜ=${_fmt(Hc)}  Cᶜ=${_fmt(Cc)}  Sᶜ=${_fmt(Sc)}  Nᶜ=${_fmt(Nc)}  Oᶜ=${_fmt(Oc)}  Aᶜ=${_fmt(Ac)}',
        'Перевірка суми: ${_fmt(sumDry, d: 3)} %',
        '',
        'Горюча маса (%):',
        'Hᵍ=${_fmt(Hg)}  Cᵍ=${_fmt(Cg)}  Sᵍ=${_fmt(Sg)}  Nᵍ=${_fmt(Ng)}  Oᵍ=${_fmt(Og)}',
        'Перевірка суми: ${_fmt(sumComb, d: 3)} %',
        '',
        'Нижча теплота згоряння:',
        'Qʳ (робоча) = ${_fmt(Qr_MJ, d: 4)} МДж/кг',
        'Qᵈ (суха)   = ${_fmt(Qd_MJ, d: 4)} МДж/кг',
        'Qᵍ (горюча) = ${_fmt(Qg_MJ, d: 4)} МДж/кг',
      ].join('\n');
    });
  }

  @override
  void dispose() {
    for (final c in [_h, _c, _s, _n, _o, _w, _a]) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _field(String label, TextEditingController c) {
    return TextField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Практична №1 — калькулятор палива')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Введи склад робочої маси (у %):'),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _field('Hᵖ (%)', _h),
                _field('Cᵖ (%)', _c),
                _field('Sᵖ (%)', _s),
                _field('Nᵖ (%)', _n),
                _field('Oᵖ (%)', _o),
                _field('Wᵖ (%)', _w),
                _field('Aᵖ (%)', _a),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _calc,
                child: const Text('Розрахувати'),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _out.isEmpty ? 'Натисни "Розрахувати".' : _out,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}