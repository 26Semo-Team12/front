// lib/features/home/views/location_picker.dart
import 'package:flutter/material.dart';
import 'package:front/core/models/user_profile.dart';

const Map<String, List<String>> kLocationPresets = {
  '서울특별시': ['강남구', '강북구', '마포구', '송파구', '서초구', '종로구', '중구', '용산구'],
  '경기도': ['수원시', '성남시', '고양시', '용인시', '부천시', '안산시', '안양시', '남양주시'],
  '부산광역시': ['해운대구', '수영구', '사하구', '부산진구', '동래구', '남구', '북구', '강서구'],
  '인천광역시': ['남동구', '부평구', '계양구', '서구', '미추홀구', '연수구', '중구', '동구'],
  '대구광역시': ['달서구', '수성구', '북구', '동구', '서구', '남구', '중구'],
  '대전광역시': ['서구', '유성구', '대덕구', '동구', '중구'],
};

class LocationPicker extends StatefulWidget {
  final void Function(LocationModel) onSelected;
  const LocationPicker({super.key, required this.onSelected});

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  String? _selectedProvince;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          if (_selectedProvince != null)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => _selectedProvince = null),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          if (_selectedProvince != null) const SizedBox(width: 8),
          Text(_selectedProvince ?? '시/도 선택'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: _selectedProvince == null
            ? _buildProvinceList()
            : _buildDistrictList(_selectedProvince!),
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() => _selectedProvince = null);
            Navigator.of(context).pop();
          },
          child: const Text('취소'),
        ),
      ],
    );
  }

  Widget _buildProvinceList() {
    return ListView(
      shrinkWrap: true,
      children: kLocationPresets.keys.map((province) {
        return ListTile(
          title: Text(province),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => setState(() => _selectedProvince = province),
        );
      }).toList(),
    );
  }

  Widget _buildDistrictList(String province) {
    final districts = kLocationPresets[province] ?? [];
    return ListView(
      shrinkWrap: true,
      children: [
        ListTile(
          title: Text('[$province 전체]'),
          onTap: () {
            widget.onSelected(LocationModel(province: province, district: ''));
            Navigator.of(context).pop();
          },
        ),
        ...districts.map((district) => ListTile(
              title: Text(district),
              onTap: () {
                widget.onSelected(
                    LocationModel(province: province, district: district));
                Navigator.of(context).pop();
              },
            )),
      ],
    );
  }
}
