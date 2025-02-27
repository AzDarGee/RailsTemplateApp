require "test_helper"

class Ai::MessagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @ai_message = ai_messages(:one)
  end

  test "should get index" do
    get ai_messages_url
    assert_response :success
  end

  test "should get new" do
    get new_ai_message_url
    assert_response :success
  end

  test "should create ai_message" do
    assert_difference("Ai::Message.count") do
      post ai_messages_url, params: { ai_message: { content: @ai_message.content, conversation_id: @ai_message.conversation_id, role: @ai_message.role, tool_call_id: @ai_message.tool_call_id, tool_calls: @ai_message.tool_calls } }
    end

    assert_redirected_to ai_message_url(Ai::Message.last)
  end

  test "should show ai_message" do
    get ai_message_url(@ai_message)
    assert_response :success
  end

  test "should get edit" do
    get edit_ai_message_url(@ai_message)
    assert_response :success
  end

  test "should update ai_message" do
    patch ai_message_url(@ai_message), params: { ai_message: { content: @ai_message.content, conversation_id: @ai_message.conversation_id, role: @ai_message.role, tool_call_id: @ai_message.tool_call_id, tool_calls: @ai_message.tool_calls } }
    assert_redirected_to ai_message_url(@ai_message)
  end

  test "should destroy ai_message" do
    assert_difference("Ai::Message.count", -1) do
      delete ai_message_url(@ai_message)
    end

    assert_redirected_to ai_messages_url
  end
end
