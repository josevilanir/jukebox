require "application_system_test_case"

class RoomsTest < ApplicationSystemTestCase
  # ---- Listagem de salas ----

  test "homepage lists active rooms" do
    visit root_path
    if page.has_css?("#name-modal", wait: 2)
      fill_in "name", with: "Visitante"
      click_button "Entrar"
    end

    assert_text "Rock Room"
    assert_text "DJ Room"
    refute_text "Closed Room"
  end

  # ---- Criação de sala ----

  test "user can create a new room" do
    visit root_path
    if page.has_css?("#name-modal", wait: 2)
      fill_in "name", with: "Test DJ"
      click_button "Entrar"
    end

    click_link "Criar nova sala"
    fill_in "Nome da sala", with: "Minha Festa"
    click_button "Criar sala"

    assert_text "Minha Festa"
    assert_current_path(/minha-festa/)
  end

  # ---- Modal de nome ----

  test "new user sees name modal on first visit" do
    visit root_path
    assert_css "#name-modal"
    assert_text "Qual é o seu nome?"
  end

  test "name modal disappears after submitting name" do
    visit root_path
    assert_css "#name-modal"
    fill_in "name", with: "DJ Testador"
    click_button "Entrar"

    refute_css "#name-modal"
  end

  # ---- Acesso a sala fechada ----

  test "non-host is redirected away from closed room" do
    visit room_path(rooms(:closed_room).slug)

    # O usuário não é o host (é um guest novo) — deve ser redirecionado para a listagem
    assert_current_path rooms_path
  end
end
