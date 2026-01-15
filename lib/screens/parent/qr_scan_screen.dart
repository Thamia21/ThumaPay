import 'package:flutter/material.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  bool _isScanning = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.qr_code_scanner,
                      size: 120,
                      color: _isScanning ? Colors.blue : Colors.grey.shade400,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _isScanning ? 'Scanning...' : 'Tap to start scanning',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _isScanning ? Colors.blue : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (!_isScanning)
                      const Text(
                        'Position QR code within the frame',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isScanning = !_isScanning;
                  });
                  if (_isScanning) {
                    _simulateScan();
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  _isScanning ? 'Stop Scanning' : 'Start Scanning',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showMyQrCode,
                    icon: const Icon(Icons.qr_code),
                    label: const Text('My QR Code'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _enterCodeManually,
                    icon: const Icon(Icons.keyboard),
                    label: const Text('Enter Code'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _simulateScan() {
    // Simulate scanning for 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isScanning) {
        setState(() {
          _isScanning = false;
        });
        _showScanResult();
      }
    });
  }

  void _showScanResult() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR Code Scanned'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Merchant: Thuma Pay Store'),
            SizedBox(height: 8),
            Text('Amount: R 250.00'),
            SizedBox(height: 8),
            Text('Reference: TP202401150001'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _confirmPayment();
            },
            child: const Text('Pay'),
          ),
        ],
      ),
    );
  }

  void _confirmPayment() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment processed successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showMyQrCode() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('My QR Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.qr_code_2,
                size: 100,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            const Text('user@thumapay.com'),
            const SizedBox(height: 8),
            const Text(
              'Share this QR code to receive payments',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('QR Code shared!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  void _enterCodeManually() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Code Manually'),
        content: const TextField(
          decoration: InputDecoration(
            labelText: 'Enter payment code',
            border: OutlineInputBorder(),
            hintText: 'TP202401150001',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
