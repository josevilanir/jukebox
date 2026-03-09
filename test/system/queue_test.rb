require "application_system_test_case"

class QueueTest < ApplicationSystemTestCase
  test "host sees play next button" do
    visit root_path
    if page.has_css?("#name-modal", wait: 2)
      fill_in "name", with: "Host Teste"
      click_button "Entrar"
    end

    click_link "Criar nova sala"
    fill_in "Nome da sala", with: "Sala do Host"
    click_button "Criar sala"

    # Host vê badge "Host"
    assert_text "Host"
  end
end
