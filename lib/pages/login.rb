class W3DHub
  class Pages
    class Login < Page
      def setup
        body.clear do
          stack(width: 1.0, height: 1.0, padding: 32) do
            background 0xff_252535

            para "Login using your W3D Hub forum account"

            flow(width: 1.0) do
              tagline "Username", width: 0.25, text_align: :right, focus: true
              edit_line ""
            end

            flow(width: 1.0) do
              tagline "Password", width: 0.25, text_align: :right
              edit_line "", type: :password
            end

            flow(width: 1.0) do
              tagline "", width: 0.25
              button "Log In"
            end
          end
        end
      end
    end
  end
end
