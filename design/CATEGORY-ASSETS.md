# SOYO SALON — 카테고리 배경 이미지 세트

6개 카테고리의 이미지 에셋을 모았습니다. 웹에 직접 사용할 수 있도록 **이미지 안에는 글자·카테고리명·모임 제목을 넣지 않았습니다.**

## 파일 안내
- `category-<name>.webp`: 1600 × 900, 모임 상세 상단 배경
- `category-<name>-card.webp`: 800 × 450, 홈·목록 카드
- `categories.json`: 카테고리 이름, 배경/강조색, 이미지 경로
- `preview-contact-sheet.jpg`: 여섯 이미지 한눈에 보기

## 카테고리 매핑
| 코드 | 카테고리 | 대표 배경색 | 포인트색 |
|---|---|---|---|
| literature | 문학 · 고전 | `#DCE5FC` | `#3456A5` |
| philosophy | 철학 · 사유 | `#E6DDF4` | `#7956A2` |
| meditation | 명상 · 마음 | `#DAE9DB` | `#3E725B` |
| writing | 글쓰기 · 창작 | `#F9DECF` | `#CB624A` |
| reading | 원서 읽기 | `#F5EDC8` | `#9F7C29` |
| free | 자유모임 | `#E5E5E5` | `#444444` |

## 웹사이트 적용
`public/images/categories/` 폴더에 WebP 파일을 복사합니다. `categories.json`의 정보대로 카테고리당 하나의 배경을 지정합니다.

```css
.event-hero {
  background-image: var(--category-image);
  background-size: cover;
  background-position: center;
  border-radius: 28px;
  min-height: 300px;
}
```

디자인 지침:
1. 이미지 자체에 텍스트를 굽지 말고 HTML 텍스트를 오버레이할 것.
2. 모임별 대표 이미지가 등록되면 카테고리 이미지보다 우선할 것.
3. 배경과 제목의 명도 대비를 확인할 것. 텍스트 영역에는 반투명 배경을 추가해도 좋음.
4. 현재 카테고리 대표 이미지는 `문학 · 고전 / 철학 · 사유 / 명상 · 마음 / 글쓰기 · 창작 / 원서 읽기 / 자유모임` 6종.
5. 모임 상태(모집 중/마감)는 배경 이미지에 표시하지 않고 UI 배지로 표시할 것.
6. 카테고리 색상은 메인 전체 화면보다 모임 카드·상세 상단 등 제한된 영역에 적용할 것.

참고: 원본은 이미지 생성 시안을 토대로 추출·보정해 웹 자산으로 만들었습니다. 개별 카테고리용 전면 사진 촬영 원본이 아니므로 고해상도 출력물보다는 웹 배경에 적합합니다.
