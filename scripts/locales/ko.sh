# Korean (ko)
#
# The file name (<language code>.sh) becomes the wrapper app's <language code>.lproj.
# Messages use printf format; with multiple arguments, use positional %1$s, %2$s.

# Wrapper app display name in this language (becomes a Spotlight search term)
LOCALE_APP_NAME="메모장"

MSG+=(
  prefix_warning              '경고'
  prefix_error                '오류'

  # Access
  term_app_terminal           '터미널'
  term_app_unknown            '사용 중인 터미널 앱'
  access_requesting           "텍스트 편집기 데이터 접근 권한을 요청합니다. 알림이 뜨면 '허용'을 눌러 주세요."
  access_needed               "텍스트 편집기 설정을 바꾸려면 '%s'에 전체 디스크 접근 권한이 필요합니다."
  access_waiting              "시스템 설정 > 개인정보 보호 및 보안 > 전체 디스크 접근 권한에서 '%s'을(를) 켜 주세요.\n    권한이 확인되면 자동으로 계속합니다. macOS가 앱을 다시 열라고 하면, 다시 연 뒤 같은 명령을 다시 실행하세요.\n    권한 없이 계속하려면 s 키를 누르세요 (텍스트 편집기 설정을 건너뜁니다)."
  access_granted              '권한이 확인되었습니다.'
  access_no_tty               '키 입력을 받을 수 없는 환경이라 권한을 기다리지 않고 텍스트 편집기 설정을 건너뜁니다.'
  access_alert_title          '텍스트 편집기 설정에 접근할 수 없습니다'
  access_alert_body           "Notepad 설치/제거 스크립트가 텍스트 편집기 설정을 바꾸려면 '%s'에 전체 디스크 접근 권한이 필요합니다.\n\n시스템 설정에서 권한을 켜면 자동으로 계속합니다.\n권한 없이 계속하려면 터미널에서 s 키를 누르세요."
  access_alert_close          '닫기'
  access_alert_open           '시스템 설정 열기'

  # TextEdit settings skipped
  textedit_skipped            "권한이 부여되지 않아 텍스트 편집기 설정을 건너뛰었습니다.\n  설정이 필요하면 텍스트 편집기 > 설정 > 새로운 문서에서 '일반 텍스트'를 선택하고 '스마트 따옴표'를 끄거나,\n  '%1\$s'에 전체 디스크 접근 권한을 부여한 뒤 다음 명령으로 다시 설치하세요:\n    %2\$s"
  restore_not_needed          '설치할 때 텍스트 편집기 설정을 건너뛰었으므로 복원할 설정이 없습니다.'
  restore_skipped             "권한이 부여되지 않아 텍스트 편집기 설정을 복원하지 않았습니다. 백업은 남겨 두었습니다: %1\$s\n  '%2\$s'에 전체 디스크 접근 권한을 부여한 뒤 다음 명령으로 직접 복원할 수 있습니다:\n%3\$s"

  # Spotlight
  spotlight_requesting        'Spotlight 색인 요청: %s'
  spotlight_done              'Spotlight 색인 완료'
  spotlight_unhealthy         'Spotlight 색인에 실패했습니다 (%1$s):\n  %2$s\n  대부분의 경우 시간이 지나면 시스템이 자동으로 색인합니다!\n  혹은 다음 명령으로 색인을 다시 만들 수 있습니다 (시간이 걸리고 관리자 암호가 필요합니다):\n    sudo mdutil -i on %1$s && sudo mdutil -E %1$s'
  spotlight_pending           '아직 Spotlight 색인에 반영되지 않았습니다. 잠시 후 다시 검색해 보세요.'

  # Install
  target_app_missing          '%s 을(를) 찾을 수 없습니다.'
  app_dir_not_writable        '%s 에 쓸 수 없습니다. 다른 폴더를 지정하세요 (예: ~/Applications).'
  app_exists_foreign          '%s 이(가) 이미 있고, 이 도구가 만든 앱이 아닙니다.'
  app_creating                '래퍼 앱 생성: %s'
  lsregister_failed           'LaunchServices 등록에 실패했습니다.'
  backup_kept                 '기존 텍스트 편집기 설정 백업을 유지합니다: %s'
  backup_creating             '텍스트 편집기 설정 백업: %s'
  backup_type_unsupported     '%1$s 의 타입(%2$s)은 백업할 수 없어 건너뜁니다.'
  setting_apply               '텍스트 편집기 설정: %1$s = %2$s'
  textedit_running_apply      '텍스트 편집기가 실행 중입니다. 변경된 설정은 텍스트 편집기를 다시 실행한 뒤 적용됩니다.'
  install_done                '완료. Spotlight에서 %s(으)로 검색할 수 있습니다.'
  install_done_pending        '완료. Spotlight 색인이 끝나면 %s(으)로 검색할 수 있습니다.'

  # Uninstall
  app_already_gone            '래퍼 앱이 이미 없습니다: %s'
  app_foreign_skip            '%s 은(는) 이 도구가 만든 앱이 아니므로 삭제하지 않습니다.'
  app_removing                '래퍼 앱 삭제: %s'
  setting_restore_default     '텍스트 편집기 설정 복원: %s (기본값)'
  setting_restore             '텍스트 편집기 설정 복원: %1$s = %2$s'
  textedit_running_restore    '텍스트 편집기가 실행 중입니다. 복원된 설정은 텍스트 편집기를 다시 실행한 뒤 적용됩니다.'
  backup_missing              '설정 백업이 없어 텍스트 편집기 설정을 복원하지 않았습니다.'
  uninstall_done              '완료.'
)
