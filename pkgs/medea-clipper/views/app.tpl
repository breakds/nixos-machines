<link rel="stylesheet" href="https://unpkg.com/@picocss/pico@latest/css/pico.min.css">

<main class="container">

  <form action="/add" method="post">
    <div class="grid">
      <label for="content">
        Input:
        <input name="content" id="content" type="text" placeholder="..."/>
      </label>
      <button type="submit">Submit</button>
    </div>
  </form>

  <table>
    <thead>
      <tr>
        <th>Text</th>
        <th>Action</th>
      </tr>
    </thead>
    <tbody>
      % for idx, item in entries:
      <tr>
        <td>{{item}}</td>
        <td>
          <a href="/copy/{{idx}}">
            <button type="button">Copy</button>
          </a>
        </td>
      </tr>
      % end
    </tbody>
  </table>
</main>
