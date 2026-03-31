// lib/services/sample_sms_service.dart

/// Provides hard-coded sample bank SMS messages for demo/testing purposes.
class SampleSmsService {
  static const List<String> messages = [
    // === PROVIDED SAMPLE MESSAGES ===
    'LKR 150.00 debited from AC **1111 via POS at KOTTAWA INTERCHANGE 10500302\n28/03/2026 14:19:13\nTo Inq Call 0112303050\nGet protected - Do not Share OTP',

    'LKR 1,692.00 debited from AC **1114 via POS at KEELLS SUPER - KOTTAWA 10402483\n25/03/2026 17:46:49\nTo Inq Call 0112303050\nGet protected - Do not Share OTP',

    'LKR 5,970.00 debited from AC **1114 via POS at P AND B FUEL MART 10000759\n25/03/2026 18:58:40\nTo Inq Call 0112303050\nGet protected - Do not Share OTP',
  
    // === ADDITIONAL MOCK MESSAGES ===

    // Income / credited
    'LKR 85,000.00 credited to AC **2201 Salary Transfer from XYZ PVT LTD\n31/03/2026 09:00:00\nTo Inq Call 0112303050\nGet protected - Do not Share OTP',

    // Food
    'LKR 2,350.00 debited from AC **1111 via POS at CAFE COURT COLOMBO 10290184\n30/03/2026 12:45:22\nTo Inq Call 0112303050\nGet protected - Do not Share OTP',

    // Utilities - Dialog
    'LKR 2,999.00 debited from AC **1111 via POS at DIALOG AXIATA PLC 10018291\n29/03/2026 10:15:00\nTo Inq Call 0112303050\nGet protected - Do not Share OTP',

    // Pharmacy / Health
    'LKR 3,450.00 debited from AC **1114 via POS at OASYS PHARMACY KOTTAWA 10099201\n27/03/2026 16:30:00\nTo Inq Call 0112303050\nGet protected - Do not Share OTP',

    // Shopping / Fashion
    'LKR 7,800.00 debited from AC **1111 via POS at COTTON COLLECTION STORE 10111203\n26/03/2026 15:00:00\nTo Inq Call 0112303050\nGet protected - Do not Share OTP',

    // Entertainment
    'LKR 1,100.00 debited from AC **1114 via POS at SAVOY CINEMA COLOMBO 10071928\n24/03/2026 20:00:00\nTo Inq Call 0112303050\nGet protected - Do not Share OTP',

    // Groceries - Cargills
    'LKR 4,210.00 debited from AC **1111 via POS at CARGILLS FOOD CITY KOTTAWA 10202910\n23/03/2026 11:20:30\nTo Inq Call 0112303050\nGet protected - Do not Share OTP',
  ];
}
