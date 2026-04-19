module W3DHubLauncher
  module Page
    module Boot
      class Terms < CyberarmEngine::Page
        include GuiExt

        TERMS_AND_CONDITIONS = <<~TERMS
        THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.

        IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
        TERMS

        def setup
          flow(width: 1.0, background_nine_slice: NINE_SLICE_ROUNDED, background_nine_slice_from_edge: 8, background_nine_slice_color: 0x11_ffffff, padding: HALF_PADDING) do
            banner "Terms and Conditions", width: 1.0, text_align: :center
          end

          stack(width: 1.0, fill: true, padding: PADDING) do
            stack(width: 1.0, fill: true, scroll: true, padding_bottom: PADDING) do
              tagline TERMS_AND_CONDITIONS, font: FONT_REGULAR
            end

            flow(width: 1.0) do
              flow(fill: true)
              button "Decline", margin_right: PADDING do
                window.close
              end

              button "Accept" do
                page(Page::Boot::InitialSetup)
              end
            end
          end
        end
      end
    end
  end
end
