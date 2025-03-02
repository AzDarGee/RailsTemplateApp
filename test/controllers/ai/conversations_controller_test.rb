require "test_helper"

class Ai::ConversationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @ai_conversation = ai_conversations(:one)
  end

  test "should get index" do
    get ai_conversations_url
    assert_response :success
  end

  test "should get new" do
    get new_ai_conversation_url
    assert_response :success
  end

  test "should create ai_conversation" do
    assert_difference("Ai::Conversation.count") do
      post ai_conversations_url, params: { ai_conversation: { category: @ai_conversation.category, title: @ai_conversation.title, user_id: @ai_conversation.user_id } }
    end

    assert_redirected_to ai_conversation_url(Ai::Conversation.last)
  end

  test "should show ai_conversation" do
    get ai_conversation_url(@ai_conversation)
    assert_response :success
  end

  test "should get edit" do
    get edit_ai_conversation_url(@ai_conversation)
    assert_response :success
  end

  test "should update ai_conversation" do
    patch ai_conversation_url(@ai_conversation), params: { ai_conversation: { category: @ai_conversation.category, title: @ai_conversation.title, user_id: @ai_conversation.user_id } }
    assert_redirected_to ai_conversation_url(@ai_conversation)
  end

  test "should destroy ai_conversation" do
    assert_difference("Ai::Conversation.count", -1) do
      delete ai_conversation_url(@ai_conversation)
    end

    assert_redirected_to ai_conversations_url
  end
end
