// lib/features/home/views/location_picker.dart
import 'package:flutter/material.dart';
import 'package:front/core/models/user_profile.dart';

// ── 파자 분해 기반 퍼지 매칭 ──────────────────────────────────────────────────
const _chosungList = [
  'ㄱ','ㄲ','ㄴ','ㄷ','ㄸ','ㄹ','ㅁ','ㅂ','ㅃ','ㅅ',
  'ㅆ','ㅇ','ㅈ','ㅉ','ㅊ','ㅋ','ㅌ','ㅍ','ㅎ',
];

({int cho, int jung, int jong})? _decompose(String c) {
  final code = c.codeUnitAt(0);
  if (code < 0xAC00 || code > 0xD7A3) return null;
  final o = code - 0xAC00;
  return (cho: o ~/ 588, jung: (o % 588) ~/ 28, jong: o % 28);
}

bool _isJamo(String c) {
  final code = c.codeUnitAt(0);
  return code >= 0x3131 && code <= 0x314E;
}

bool _charMatches(String q, String w, {required bool isLast}) {
  if (_isJamo(q)) {
    final qi = _chosungList.indexOf(q);
    if (qi < 0) return q == w;
    final wd = _decompose(w);
    return wd != null && wd.cho == qi;
  }
  final qd = _decompose(q);
  if (qd == null) return q.toLowerCase() == w.toLowerCase();
  final wd = _decompose(w);
  if (wd == null) return false;
  if (qd.cho != wd.cho || qd.jung != wd.jung) return false;
  if (isLast) return qd.jong == 0 || qd.jong == wd.jong;
  return qd.jong == wd.jong;
}

bool _fuzzyMatch(String word, String query) {
  if (query.isEmpty) return true;
  final qc = query.characters.toList();
  final wc = word.characters.toList();
  if (qc.length > wc.length) return false;
  for (var s = 0; s <= wc.length - qc.length; s++) {
    bool ok = true;
    for (var i = 0; i < qc.length; i++) {
      if (!_charMatches(qc[i], wc[s + i], isLast: i == qc.length - 1)) {
        ok = false;
        break;
      }
    }
    if (ok) return true;
  }
  return false;
}

// ── 지역 데이터 (도/광역시 → 시/군 → 구)
// 구가 없는 시/군은 빈 리스트로 표기
const Map<String, Map<String, List<String>>> kLocationData = {
  // ── 서울특별시 ──────────────────────────────────────────────────────────────
  '서울특별시': {
    '': [
      '강남구','강동구','강북구','강서구','관악구','광진구','구로구','금천구',
      '노원구','도봉구','동대문구','동작구','마포구','서대문구','서초구','성동구',
      '성북구','송파구','양천구','영등포구','용산구','은평구','종로구','중구','중랑구',
    ],
  },
  // ── 부산광역시 ──────────────────────────────────────────────────────────────
  '부산광역시': {
    '': [
      '강서구','금정구','기장군','남구','동구','동래구','부산진구','북구',
      '사상구','사하구','서구','수영구','연제구','영도구','중구','해운대구',
    ],
  },
  // ── 대구광역시 ──────────────────────────────────────────────────────────────
  '대구광역시': {
    '': ['남구','달서구','달성군','동구','북구','서구','수성구','중구'],
  },
  // ── 인천광역시 ──────────────────────────────────────────────────────────────
  '인천광역시': {
    '': ['강화군','계양구','남동구','동구','미추홀구','부평구','서구','연수구','옹진군','중구'],
  },
  // ── 광주광역시 ──────────────────────────────────────────────────────────────
  '광주광역시': {
    '': ['광산구','남구','동구','북구','서구'],
  },
  // ── 대전광역시 ──────────────────────────────────────────────────────────────
  '대전광역시': {
    '': ['대덕구','동구','서구','유성구','중구'],
  },
  // ── 울산광역시 ──────────────────────────────────────────────────────────────
  '울산광역시': {
    '': ['남구','동구','북구','울주군','중구'],
  },
  // ── 세종특별자치시 ──────────────────────────────────────────────────────────
  '세종특별자치시': {
    '세종시': [],
  },
  // ── 경기도 ──────────────────────────────────────────────────────────────────
  '경기도': {
    '수원시': ['권선구','영통구','장안구','팔달구'],
    '성남시': ['분당구','수정구','중원구'],
    '의정부시': [],
    '안양시': ['동안구','만안구'],
    '부천시': ['소사구','오정구','원미구'],
    '광명시': [],
    '평택시': [],
    '동두천시': [],
    '안산시': ['단원구','상록구'],
    '고양시': ['덕양구','일산동구','일산서구'],
    '과천시': [],
    '구리시': [],
    '남양주시': [],
    '오산시': [],
    '시흥시': [],
    '군포시': [],
    '의왕시': [],
    '하남시': [],
    '용인시': ['기흥구','수지구','처인구'],
    '파주시': [],
    '이천시': [],
    '안성시': [],
    '김포시': [],
    '화성시': [],
    '광주시': [],
    '양주시': [],
    '포천시': [],
    '여주시': [],
    '연천군': [],
    '가평군': [],
    '양평군': [],
  },
  // ── 강원특별자치도 ──────────────────────────────────────────────────────────
  '강원특별자치도': {
    '춘천시': [],
    '원주시': [],
    '강릉시': [],
    '동해시': [],
    '태백시': [],
    '속초시': [],
    '삼척시': [],
    '홍천군': [],
    '횡성군': [],
    '영월군': [],
    '평창군': [],
    '정선군': [],
    '철원군': [],
    '화천군': [],
    '양구군': [],
    '인제군': [],
    '고성군': [],
    '양양군': [],
  },
  // ── 충청북도 ────────────────────────────────────────────────────────────────
  '충청북도': {
    '청주시': ['상당구','서원구','청원구','흥덕구'],
    '충주시': [],
    '제천시': [],
    '보은군': [],
    '옥천군': [],
    '영동군': [],
    '증평군': [],
    '진천군': [],
    '괴산군': [],
    '음성군': [],
    '단양군': [],
  },
  // ── 충청남도 ────────────────────────────────────────────────────────────────
  '충청남도': {
    '천안시': ['동남구','서북구'],
    '공주시': [],
    '보령시': [],
    '아산시': [],
    '서산시': [],
    '논산시': [],
    '계룡시': [],
    '당진시': [],
    '금산군': [],
    '부여군': [],
    '서천군': [],
    '청양군': [],
    '홍성군': [],
    '예산군': [],
    '태안군': [],
  },
  // ── 전북특별자치도 ──────────────────────────────────────────────────────────
  '전북특별자치도': {
    '전주시': ['덕진구','완산구'],
    '군산시': [],
    '익산시': [],
    '정읍시': [],
    '남원시': [],
    '김제시': [],
    '완주군': [],
    '진안군': [],
    '무주군': [],
    '장수군': [],
    '임실군': [],
    '순창군': [],
    '고창군': [],
    '부안군': [],
  },
  // ── 전라남도 ────────────────────────────────────────────────────────────────
  '전라남도': {
    '목포시': [],
    '여수시': [],
    '순천시': [],
    '나주시': [],
    '광양시': [],
    '담양군': [],
    '곡성군': [],
    '구례군': [],
    '고흥군': [],
    '보성군': [],
    '화순군': [],
    '장흥군': [],
    '강진군': [],
    '해남군': [],
    '영암군': [],
    '무안군': [],
    '함평군': [],
    '영광군': [],
    '장성군': [],
    '완도군': [],
    '진도군': [],
    '신안군': [],
  },
  // ── 경상북도 ────────────────────────────────────────────────────────────────
  '경상북도': {
    '포항시': ['남구','북구'],
    '경주시': [],
    '김천시': [],
    '안동시': [],
    '구미시': [],
    '영주시': [],
    '영천시': [],
    '상주시': [],
    '문경시': [],
    '경산시': [],
    '군위군': [],
    '의성군': [],
    '청송군': [],
    '영양군': [],
    '영덕군': [],
    '청도군': [],
    '고령군': [],
    '성주군': [],
    '칠곡군': [],
    '예천군': [],
    '봉화군': [],
    '울진군': [],
    '울릉군': [],
  },
  // ── 경상남도 ────────────────────────────────────────────────────────────────
  '경상남도': {
    '창원시': ['마산합포구','마산회원구','성산구','의창구','진해구'],
    '진주시': [],
    '통영시': [],
    '사천시': [],
    '김해시': [],
    '밀양시': [],
    '거제시': [],
    '양산시': [],
    '의령군': [],
    '함안군': [],
    '창녕군': [],
    '고성군': [],
    '남해군': [],
    '하동군': [],
    '산청군': [],
    '함양군': [],
    '거창군': [],
    '합천군': [],
  },
  // ── 제주특별자치도 ──────────────────────────────────────────────────────────
  '제주특별자치도': {
    '제주시': [],
    '서귀포시': [],
  },
};

// 검색용 플랫 리스트 생성
List<LocationModel> _buildAllLocations() {
  final result = <LocationModel>[];
  for (final prov in kLocationData.entries) {
    for (final city in prov.value.entries) {
      if (city.key.isEmpty) {
        // 광역시/특별시: 구 단위가 바로 있음
        for (final gu in city.value) {
          result.add(LocationModel(province: prov.key, district: gu));
        }
      } else if (city.value.isEmpty) {
        // 구 없는 시/군
        result.add(LocationModel(province: prov.key, district: city.key));
      } else {
        // 구 있는 시: 시 전체 + 각 구
        result.add(LocationModel(province: prov.key, district: city.key));
        for (final gu in city.value) {
          result.add(LocationModel(province: prov.key, district: '${city.key} $gu'));
        }
      }
    }
  }
  return result;
}

final _allLocations = _buildAllLocations();

// 현재 위치 기준 모의 주변 지역
final _mockNearby = [
  const LocationModel(province: '경기도', district: '수원시 영통구'),
  const LocationModel(province: '경기도', district: '수원시 팔달구'),
  const LocationModel(province: '경기도', district: '수원시 권선구'),
  const LocationModel(province: '경기도', district: '수원시 장안구'),
  const LocationModel(province: '경기도', district: '용인시 기흥구'),
  const LocationModel(province: '경기도', district: '화성시'),
  const LocationModel(province: '경기도', district: '오산시'),
  const LocationModel(province: '경기도', district: '의왕시'),
];

class LocationPicker extends StatefulWidget {
  final void Function(LocationModel) onSelected;
  const LocationPicker({super.key, required this.onSelected});

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  final _searchController = TextEditingController();
  List<LocationModel> _results = [];
  bool _isSearching = false;
  bool _showNearby = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearch);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchController.text.trim();
    setState(() {
      _isSearching = q.isNotEmpty;
      if (_isSearching) {
        _results = _allLocations.where((loc) {
          return _fuzzyMatch(loc.province, q) ||
              _fuzzyMatch(loc.district, q) ||
              _fuzzyMatch(loc.displayLabel, q);
        }).toList();
      }
    });
  }

  void _select(LocationModel loc) {
    widget.onSelected(loc);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      // 세로 길이 고정
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.72,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('주 활동 지역 선택',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // 검색바
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '지역 검색 (예: 영통구, 수원)',
                  prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                  suffixIcon: _isSearching
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // 목록 영역 (Expanded로 나머지 공간 채움)
            Expanded(
              child: _isSearching ? _buildSearchResults() : _buildBrowse(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_results.isEmpty) {
      return const Center(
        child: Text('검색 결과가 없습니다.', style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (_, i) {
        final loc = _results[i];
        return ListTile(
          leading: const Icon(Icons.place_outlined, color: Color(0xFFD6706D), size: 20),
          title: Text(loc.displayLabel, style: const TextStyle(fontSize: 15)),
          onTap: () => _select(loc),
        );
      },
    );
  }

  Widget _buildBrowse() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 현재 위치 기준 검색 버튼
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _showNearby = true),
              icon: const Icon(Icons.my_location, size: 18, color: Color(0xFFD6706D)),
              label: const Text('현재 위치를 기준으로 검색',
                  style: TextStyle(color: Color(0xFFD6706D), fontSize: 14)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFD6706D)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                minimumSize: const Size(double.infinity, 0),
              ),
            ),
          ),

          if (_showNearby) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  const Icon(Icons.near_me, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('현재 위치 기준 주변 지역',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ),
            ...List.generate(_mockNearby.length, (i) {
              final loc = _mockNearby[i];
              return ListTile(
                dense: true,
                leading: Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD6706D).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text('${i + 1}',
                      style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFD6706D),
                          fontWeight: FontWeight.bold)),
                ),
                title: Text(loc.displayLabel, style: const TextStyle(fontSize: 15)),
                subtitle: Text(
                  i == 0 ? '현재 위치' : '${(i * 1.4).toStringAsFixed(1)}km',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                onTap: () => _select(loc),
              );
            }),
          ] else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text('전체 지역',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ),
            ...kLocationData.entries.map((prov) {
              return ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                leading: const Icon(Icons.location_city_outlined,
                    size: 20, color: Colors.grey),
                title: Text(prov.key, style: const TextStyle(fontSize: 15)),
                children: prov.value.entries.expand((city) {
                  if (city.key.isEmpty) {
                    // 광역시: 구 바로 나열
                    return city.value.map((gu) => _districtTile(
                          label: '${prov.key} $gu',
                          loc: LocationModel(province: prov.key, district: gu),
                        ));
                  }
                  if (city.value.isEmpty) {
                    // 구 없는 시/군
                    return [
                      _districtTile(
                        label: '${prov.key} ${city.key}',
                        loc: LocationModel(province: prov.key, district: city.key),
                      )
                    ];
                  }
                  // 구 있는 시: 전체 + 각 구
                  return [
                    _districtTile(
                      label: '${prov.key} ${city.key} 전체',
                      loc: LocationModel(province: prov.key, district: city.key),
                    ),
                    ...city.value.map((gu) => _districtTile(
                          label: '${prov.key} ${city.key} $gu',
                          loc: LocationModel(
                              province: prov.key, district: '${city.key} $gu'),
                        )),
                  ];
                }).toList(),
              );
            }),
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _districtTile({required String label, required LocationModel loc}) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.only(left: 56, right: 16),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      onTap: () => _select(loc),
    );
  }
}
